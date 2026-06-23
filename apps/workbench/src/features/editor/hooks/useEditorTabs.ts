import { useCallback } from "react";

import { useEditorStore } from "@/features/editor/stores/editorStore";
import { useWorkspaceStore } from "@/features/workspace/stores/workspaceStore";

export function useEditorTabs() {
  const openPaths = useWorkspaceStore((s) => s.openPaths);
  const closeFile = useWorkspaceStore((s) => s.closeFile);
  const clearDraft = useEditorStore((s) => s.clearDraft);
  const draftsByPath = useEditorStore((s) => s.draftsByPath);

  const dirtyPaths = new Set(
    Object.entries(draftsByPath)
      .filter(([, draft]) => draft.isDirty)
      .map(([path]) => path),
  );

  const closeTab = useCallback(
    (path: string) => {
      const draft = useEditorStore.getState().getDraft(path);
      if (draft?.isDirty) {
        const confirmed = window.confirm(
          `You have unsaved edits in ${path.split("/").pop()}. Close without saving?`,
        );
        if (!confirmed) {
          return;
        }
      }
      clearDraft(path);
      closeFile(path);
    },
    [clearDraft, closeFile],
  );

  return {
    openPaths,
    dirtyPaths,
    closeTab,
  };
}
