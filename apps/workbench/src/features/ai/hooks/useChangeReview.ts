import { useMutation, useQueryClient } from "@tanstack/react-query";
import { useCallback, useMemo, useState } from "react";

import { applyChangePlan, discardChangePlan } from "@/features/ai/api/editsApi";
import { useChatStore } from "@/features/ai/stores/chatStore";
import { documentKeys, fetchDocument } from "@/features/editor/api/documentsApi";
import { planChangeUnits, resolvePreviewBody } from "@/features/editor/lib/applyHunks";
import { useEditorStore } from "@/features/editor/stores/editorStore";
import { invalidateWorkspaceTree } from "@/features/workspace/hooks/useDocTree";
import type { ChangePlan } from "@/shared/types/chat";

export function useChangeReview(documentPath: string | null) {
  const queryClient = useQueryClient();
  const pendingPlan = useChatStore((s) => s.pendingPlan);
  const acceptedHunkIds = useChatStore((s) => s.acceptedHunkIds);
  const setPendingPlan = useChatStore((s) => s.setPendingPlan);
  const toggleHunk = useChatStore((s) => s.toggleHunk);
  const setHunkAccepted = useChatStore((s) => s.setHunkAccepted);
  const acceptAllHunks = useChatStore((s) => s.acceptAllHunks);
  const rejectAllHunks = useChatStore((s) => s.rejectAllHunks);
  const getAcceptedHunkIdList = useChatStore((s) => s.getAcceptedHunkIdList);
  const setDraftContent = useEditorStore((s) => s.setDraftContent);
  const clearDraft = useEditorStore((s) => s.clearDraft);
  const [lastCommittedAt, setLastCommittedAt] = useState<string | null>(null);
  const [lastDiskPath, setLastDiskPath] = useState<string | null>(null);

  const isActive = Boolean(
    pendingPlan && documentPath && pendingPlan.documentPath === documentPath,
  );

  const changeUnits = useMemo(
    () => (pendingPlan ? planChangeUnits(pendingPlan) : []),
    [pendingPlan],
  );

  const acceptedIdSet = useMemo(
    () =>
      new Set(
        Object.entries(acceptedHunkIds)
          .filter(([, accepted]) => accepted)
          .map(([id]) => id),
      ),
    [acceptedHunkIds],
  );

  const acceptedCount = useMemo(
    () => Object.values(acceptedHunkIds).filter(Boolean).length,
    [acceptedHunkIds],
  );

  const syncDocumentAfterCommit = useCallback(
    async (path: string, expectedChecksum: string) => {
      clearDraft(path);
      queryClient.removeQueries({ queryKey: documentKeys.detail(path) });
      const document = await fetchDocument(path);
      if (document.checksum !== expectedChecksum) {
        throw new Error("Commit did not persist to disk. Reload and try again.");
      }
      setDraftContent(path, document.content, document.checksum);
      queryClient.setQueryData(documentKeys.detail(path), document);
      invalidateWorkspaceTree(queryClient);
      setLastCommittedAt(new Date().toLocaleTimeString());
      return document;
    },
    [clearDraft, queryClient, setDraftContent],
  );

  const applyMutation = useMutation({
    mutationFn: async (plan: ChangePlan) => {
      const acceptedIds = getAcceptedHunkIdList();
      const units = planChangeUnits(plan);
      if (units.length > 0 && acceptedIds.length === 0) {
        throw new Error("Accept at least one change block to commit, or discard the proposal.");
      }
      return applyChangePlan(plan.editId, {
        acceptedHunkIds: acceptedIds,
      });
    },
    onSuccess: async (result) => {
      await syncDocumentAfterCommit(result.documentPath, result.checksum);
      setLastDiskPath(result.diskPath ?? null);
      setPendingPlan(null);
    },
  });

  const discardMutation = useMutation({
    mutationFn: (editId: string) => discardChangePlan(editId),
    onSuccess: () => {
      setPendingPlan(null);
      setLastDiskPath(null);
    },
  });

  const getPreviewBody = useCallback(
    (originalBody: string) => {
      if (!pendingPlan) {
        return originalBody;
      }
      const baseBody = pendingPlan.baseBody || originalBody;
      return resolvePreviewBody(baseBody, pendingPlan, acceptedIdSet);
    },
    [pendingPlan, acceptedIdSet],
  );

  const commitToDisk = useCallback(() => {
    if (!pendingPlan) {
      return Promise.resolve();
    }
    return applyMutation.mutateAsync(pendingPlan);
  }, [applyMutation, pendingPlan]);

  const restoreWorkingTree = useCallback(() => {
    if (!pendingPlan) {
      return Promise.resolve();
    }
    return discardMutation.mutateAsync(pendingPlan.editId);
  }, [discardMutation, pendingPlan]);

  return {
    isActive,
    pendingPlan: isActive ? pendingPlan : null,
    changeUnits,
    acceptedChangeIds: acceptedHunkIds,
    acceptedIdSet,
    acceptedCount,
    toggleAccept: toggleHunk,
    setAccepted: setHunkAccepted,
    acceptAll: acceptAllHunks,
    rejectAll: rejectAllHunks,
    getPreviewBody,
    commitToDisk,
    restoreWorkingTree,
    isCommitting: applyMutation.isPending,
    isRestoring: discardMutation.isPending,
    commitError: applyMutation.error,
    lastCommittedAt,
    lastDiskPath,
    // Legacy aliases
    acceptedHunkIds,
    toggleHunk,
    setHunkAccepted,
    acceptAllHunks,
    rejectAllHunks,
    saveToFile: commitToDisk,
    discard: restoreWorkingTree,
    isSaving: applyMutation.isPending,
    isDiscarding: discardMutation.isPending,
    saveError: applyMutation.error,
    lastSavedAt: lastCommittedAt,
  };
}
