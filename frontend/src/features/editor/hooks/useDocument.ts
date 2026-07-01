import { useMutation, useQuery, useQueryClient } from "@tanstack/react-query";
import { useCallback, useEffect } from "react";

import { documentKeys, fetchDocument, saveDocument } from "@/features/editor/api/documentsApi";
import { markEditorDirty, useEditorStore } from "@/features/editor/stores/editorStore";
import { invalidateWorkspaceTree } from "@/features/workspace/hooks/useDocTree";

export function useDocument(path: string | null) {
  const queryClient = useQueryClient();
  const setDraftContent = useEditorStore((s) => s.setDraftContent);
  const clearDraft = useEditorStore((s) => s.clearDraft);
  const getDraft = useEditorStore((s) => s.getDraft);
  const markSaved = useEditorStore((s) => s.markSaved);

  const isMarkdownFile = Boolean(path?.toLowerCase().endsWith(".md"));
  const draft = path ? getDraft(path) : undefined;

  const query = useQuery({
    queryKey: documentKeys.detail(path ?? ""),
    queryFn: () => fetchDocument(path!),
    enabled: isMarkdownFile,
    staleTime: 0,
    refetchOnMount: "always",
    refetchOnWindowFocus: false,
  });

  useEffect(() => {
    if (!path || !isMarkdownFile) {
      return;
    }
    clearDraft(path);
    queryClient.removeQueries({ queryKey: documentKeys.detail(path) });
  }, [clearDraft, isMarkdownFile, path, queryClient]);

  useEffect(() => {
    if (query.data && path) {
      setDraftContent(path, query.data.content, query.data.checksum);
    }
  }, [path, query.data, setDraftContent]);

  useEffect(() => {
    if (!path) {
      return;
    }
    const onBeforeUnload = (event: BeforeUnloadEvent) => {
      const currentDraft = useEditorStore.getState().getDraft(path);
      if (currentDraft?.isDirty) {
        event.preventDefault();
        event.returnValue = "";
      }
    };
    window.addEventListener("beforeunload", onBeforeUnload);
    return () => window.removeEventListener("beforeunload", onBeforeUnload);
  }, [path]);

  const saveMutation = useMutation({
    mutationFn: saveDocument,
    onSuccess: async (data) => {
      markSaved(data.path, data.checksum);
      await queryClient.invalidateQueries({ queryKey: documentKeys.detail(data.path) });
      const document = await fetchDocument(data.path);
      setDraftContent(data.path, document.content, document.checksum);
      queryClient.setQueryData(documentKeys.detail(data.path), document);
      invalidateWorkspaceTree(queryClient);
    },
  });

  const onContentChange = useCallback(
    (body: string) => {
      if (!path) {
        return;
      }
      markEditorDirty(path, body);
    },
    [path],
  );

  const saveNow = useCallback(async () => {
    if (!path) {
      return;
    }

    const current = useEditorStore.getState().getDraft(path);
    if (!current?.isDirty) {
      return;
    }

    await saveMutation.mutateAsync({
      path,
      content: current.draftContent,
      checksum: current.savedChecksum,
    });
  }, [path, saveMutation]);

  const reloadFromDisk = useCallback(async () => {
    if (!path) {
      return;
    }

    if (getDraft(path)?.isDirty) {
      const confirmed = window.confirm("Discard unsaved edits and reload from disk?");
      if (!confirmed) {
        return;
      }
    }

    clearDraft(path);
    queryClient.removeQueries({ queryKey: documentKeys.detail(path) });
    const document = await fetchDocument(path);
    setDraftContent(path, document.content, document.checksum);
    queryClient.setQueryData(documentKeys.detail(path), document);
  }, [clearDraft, getDraft, path, queryClient, setDraftContent]);

  return {
    isMarkdownFile,
    isLoading: query.isLoading,
    isError: query.isError,
    error: query.error,
    body: draft?.draftBody ?? "",
    frontMatter: draft?.frontMatter ?? null,
    isDirty: draft?.isDirty ?? false,
    isSaving: saveMutation.isPending,
    savedChecksum: draft?.savedChecksum ?? null,
    saveError: saveMutation.error,
    onContentChange,
    saveNow,
    reloadFromDisk,
  };
}
