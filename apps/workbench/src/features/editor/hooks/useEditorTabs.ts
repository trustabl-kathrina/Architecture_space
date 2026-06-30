import { useCallback } from "react";

import { useEditorStore } from "@/features/editor/stores/editorStore";
import { useWorkspaceStore } from "@/features/workspace/stores/workspaceStore";
import { useFolderPlanStore } from "@/features/workspace/stores/folderPlanStore";
import type { WorkbenchTab } from "@/shared/types/workspace";

export function useEditorTabs() {
  const openTabs = useWorkspaceStore((s) => s.openTabs);
  const closeTabInStore = useWorkspaceStore((s) => s.closeTab);
  const clearDraft = useEditorStore((s) => s.clearDraft);
  const draftsByPath = useEditorStore((s) => s.draftsByPath);

  const dirtyPaths = new Set(
    Object.entries(draftsByPath)
      .filter(([, draft]) => draft.isDirty)
      .map(([path]) => path),
  );

  const closeTab = useCallback(
    (tab: WorkbenchTab) => {
      if (tab.kind === "file") {
        const draft = useEditorStore.getState().getDraft(tab.path);
        if (draft?.isDirty) {
          const confirmed = window.confirm(
            `You have unsaved edits in ${tab.path.split("/").pop()}. Close without saving?`,
          );
          if (!confirmed) {
            return;
          }
        }
        clearDraft(tab.path);
      }
      closeTabInStore(tab);
    },
    [clearDraft, closeTabInStore],
  );

  return {
    openTabs,
    dirtyPaths,
    closeTab,
  };
}

export function useActiveFolderPlan(): string {
  const activeTab = useWorkspaceStore((s) => s.activeTab);
  const plan = useFolderPlanStore((s) =>
    activeTab?.kind === "folder" ? s.getPlan(activeTab.path) : "",
  );
  return plan;
}
