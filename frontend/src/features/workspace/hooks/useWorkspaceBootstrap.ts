import { useQueryClient } from "@tanstack/react-query";
import { useEffect, useRef, useState } from "react";

import { workspaceKeys } from "@/features/workspace/api/workspaceApi";
import { workspacePathExists } from "@/features/workspace/lib/pathValidation";
import { normalizeWorkspacePaths } from "@/features/workspace/lib/pathMigration";
import { useWorkspaceStore } from "@/features/workspace/stores/workspaceStore";
import { tabKey, type WorkbenchTab } from "@/shared/types/workspace";

async function reconcilePersistedTabs(): Promise<void> {
  const state = useWorkspaceStore.getState();

  const activeTab = state.activeTab;
  const openTabs = state.openTabs;
  const expandedPaths = normalizeWorkspacePaths(state.expandedPaths);

  const validOpen: WorkbenchTab[] = [];
  for (const tab of openTabs) {
    if (await workspacePathExists(tab.path)) {
      validOpen.push(tab);
    }
  }

  let validActive = activeTab;
  if (activeTab) {
    const activeExists = await workspacePathExists(activeTab.path);
    if (activeExists) {
      const key = tabKey(activeTab);
      if (!validOpen.some((tab) => tabKey(tab) === key)) {
        validOpen.unshift(activeTab);
      }
      validActive = activeTab;
    } else {
      validActive = validOpen[0] ?? null;
    }
  } else {
    validActive = validOpen[0] ?? null;
  }

  const validExpanded: string[] = [];
  for (const path of expandedPaths) {
    if (await workspacePathExists(path)) {
      validExpanded.push(path);
    }
  }

  useWorkspaceStore.setState({
    activeTab: validActive,
    openTabs: validOpen,
    expandedPaths: validExpanded,
  });
}

export function useWorkspaceBootstrap(): boolean {
  const queryClient = useQueryClient();
  const started = useRef(false);
  const [ready, setReady] = useState(false);

  useEffect(() => {
    if (started.current) {
      return;
    }
    started.current = true;

    void reconcilePersistedTabs()
      .then(() => {
        void queryClient.invalidateQueries({ queryKey: workspaceKeys.all });
      })
      .finally(() => {
        useWorkspaceStore.getState().setPathsReconciled(true);
        setReady(true);
      });
  }, [queryClient]);

  return ready;
}
