import { create } from "zustand";
import { persist } from "zustand/middleware";

import {
  normalizeWorkspacePath,
  normalizeWorkspacePaths,
} from "@/features/workspace/lib/pathMigration";

interface WorkspaceUiState {
  selectedPath: string | null;
  openPaths: string[];
  expandedPaths: string[];
  treeFilter: string;
  pathsReconciled: boolean;
  setPathsReconciled: (ready: boolean) => void;
  openFile: (path: string) => void;
  closeFile: (path: string) => void;
  setSelectedPath: (path: string | null) => void;
  toggleExpanded: (path: string) => void;
  expandPath: (path: string) => void;
  collapsePath: (path: string) => void;
  setTreeFilter: (filter: string) => void;
  isExpanded: (path: string) => boolean;
}

function normalizeOpenPaths(openPaths: string[], selectedPath: string | null): string[] {
  if (selectedPath && !openPaths.includes(selectedPath)) {
    return [selectedPath, ...openPaths];
  }
  return openPaths;
}

function normalizePersistedState(state: Partial<WorkspaceUiState>): Partial<WorkspaceUiState> {
  const selectedPath = state.selectedPath ? normalizeWorkspacePath(state.selectedPath) : null;
  const openPaths = normalizeWorkspacePaths(state.openPaths ?? []);
  const expandedPaths = normalizeWorkspacePaths(state.expandedPaths ?? []);
  return {
    ...state,
    selectedPath,
    openPaths: normalizeOpenPaths(openPaths, selectedPath),
    expandedPaths,
  };
}

export const useWorkspaceStore = create<WorkspaceUiState>()(
  persist(
    (set, get) => ({
      selectedPath: null,
      openPaths: [],
      expandedPaths: [],
      treeFilter: "",
      pathsReconciled: false,
      setPathsReconciled: (ready) => set({ pathsReconciled: ready }),

      openFile: (path) => {
        const normalized = normalizeWorkspacePath(path);
        const { openPaths } = get();
        set({
          selectedPath: normalized,
          openPaths: openPaths.includes(normalized) ? openPaths : [...openPaths, normalized],
        });
      },

      closeFile: (path) => {
        const normalized = normalizeWorkspacePath(path);
        const { openPaths, selectedPath } = get();
        const nextOpen = openPaths.filter((item) => item !== normalized);
        let nextSelected = selectedPath;
        if (selectedPath === normalized) {
          const closedIndex = openPaths.indexOf(normalized);
          nextSelected = nextOpen[Math.min(closedIndex, nextOpen.length - 1)] ?? null;
        }
        set({ openPaths: nextOpen, selectedPath: nextSelected });
      },

      setSelectedPath: (path) => {
        if (path) {
          get().openFile(path);
          return;
        }
        set({ selectedPath: null });
      },

      toggleExpanded: (path) => {
        const normalized = normalizeWorkspacePath(path);
        const { expandedPaths } = get();
        if (expandedPaths.includes(normalized)) {
          set({ expandedPaths: expandedPaths.filter((p) => p !== normalized) });
        } else {
          set({ expandedPaths: [...expandedPaths, normalized] });
        }
      },

      expandPath: (path) => {
        const normalized = normalizeWorkspacePath(path);
        const { expandedPaths } = get();
        if (!expandedPaths.includes(normalized)) {
          set({ expandedPaths: [...expandedPaths, normalized] });
        }
      },

      collapsePath: (path) => {
        const normalized = normalizeWorkspacePath(path);
        set({ expandedPaths: get().expandedPaths.filter((p) => p !== normalized) });
      },

      setTreeFilter: (filter) => set({ treeFilter: filter }),

      isExpanded: (path) => get().expandedPaths.includes(normalizeWorkspacePath(path)),
    }),
    {
      name: "kew-workspace-ui",
      version: 2,
      partialize: (state) => ({
        expandedPaths: state.expandedPaths,
        selectedPath: state.selectedPath,
        openPaths: state.openPaths,
      }),
      migrate: (persisted, version) => {
        if (version < 2) {
          return normalizePersistedState(persisted as Partial<WorkspaceUiState>);
        }
        return persisted;
      },
      merge: (persisted, current) => {
        const merged = {
          ...current,
          ...normalizePersistedState(persisted as Partial<WorkspaceUiState>),
        };
        merged.openPaths = normalizeOpenPaths(merged.openPaths ?? [], merged.selectedPath);
        return merged;
      },
    },
  ),
);
