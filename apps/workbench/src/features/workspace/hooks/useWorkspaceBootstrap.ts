import { useQueryClient } from "@tanstack/react-query";
import { useEffect, useRef, useState } from "react";

import { workspaceKeys } from "@/features/workspace/api/workspaceApi";
import { workspacePathExists } from "@/features/workspace/lib/pathValidation";
import {
  normalizeWorkspacePath,
  normalizeWorkspacePaths,
} from "@/features/workspace/lib/pathMigration";
import { useWorkspaceStore } from "@/features/workspace/stores/workspaceStore";

async function reconcilePersistedPaths(): Promise<void> {
  const state = useWorkspaceStore.getState();

  const selectedPath = state.selectedPath ? normalizeWorkspacePath(state.selectedPath) : null;
  const openPaths = normalizeWorkspacePaths(state.openPaths);
  const expandedPaths = normalizeWorkspacePaths(state.expandedPaths);

  const validOpen: string[] = [];
  for (const path of openPaths) {
    if (await workspacePathExists(path)) {
      validOpen.push(path);
    }
  }

  let validSelected = selectedPath;
  if (selectedPath) {
    const selectedExists = await workspacePathExists(selectedPath);
    if (selectedExists) {
      if (!validOpen.includes(selectedPath)) {
        validOpen.unshift(selectedPath);
      }
      validSelected = selectedPath;
    } else {
      validSelected = validOpen[0] ?? null;
    }
  } else {
    validSelected = validOpen[0] ?? null;
  }

  const validExpanded: string[] = [];
  for (const path of expandedPaths) {
    if (await workspacePathExists(path)) {
      validExpanded.push(path);
    }
  }

  useWorkspaceStore.setState({
    selectedPath: validSelected,
    openPaths: validOpen,
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

    void reconcilePersistedPaths()
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
