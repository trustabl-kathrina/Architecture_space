import { create } from "zustand";
import { persist } from "zustand/middleware";

import {
  normalizeWorkspacePath,
  normalizeWorkspacePaths,
} from "@/features/workspace/lib/pathMigration";
import {
  tabKey,
  tabsEqual,
  type TabKind,
  type WorkbenchTab,
} from "@/shared/types/workspace";

interface WorkspaceUiState {
  activeTab: WorkbenchTab | null;
  openTabs: WorkbenchTab[];
  expandedPaths: string[];
  treeFilter: string;
  pathsReconciled: boolean;
  setPathsReconciled: (ready: boolean) => void;
  openTab: (tab: WorkbenchTab) => void;
  openFile: (path: string) => void;
  openFolder: (path: string) => void;
  closeTab: (tab: WorkbenchTab) => void;
  selectTab: (tab: WorkbenchTab) => void;
  toggleExpanded: (path: string) => void;
  expandPath: (path: string) => void;
  collapsePath: (path: string) => void;
  setTreeFilter: (filter: string) => void;
  isExpanded: (path: string) => boolean;
  isTabActive: (tab: WorkbenchTab) => boolean;
}

function makeTab(kind: TabKind, path: string): WorkbenchTab {
  return { kind, path: normalizeWorkspacePath(path) };
}

function normalizeOpenTabs(
  openTabs: WorkbenchTab[],
  activeTab: WorkbenchTab | null,
): WorkbenchTab[] {
  const seen = new Set<string>();
  const normalized: WorkbenchTab[] = [];
  for (const tab of openTabs) {
    const next = makeTab(tab.kind, tab.path);
    const key = tabKey(next);
    if (!seen.has(key)) {
      seen.add(key);
      normalized.push(next);
    }
  }
  if (activeTab) {
    const active = makeTab(activeTab.kind, activeTab.path);
    const key = tabKey(active);
    if (!seen.has(key)) {
      return [active, ...normalized];
    }
  }
  return normalized;
}

interface LegacyPersistedState {
  selectedPath?: string | null;
  openPaths?: string[];
  activeTab?: WorkbenchTab | null;
  openTabs?: WorkbenchTab[];
  expandedPaths?: string[];
}

function normalizePersistedState(state: LegacyPersistedState): Partial<WorkspaceUiState> {
  let openTabs = state.openTabs ?? [];
  let activeTab = state.activeTab ?? null;

  if (openTabs.length === 0 && state.openPaths?.length) {
    openTabs = state.openPaths.map((path) => makeTab("file", path));
  }
  if (!activeTab && state.selectedPath) {
    activeTab = makeTab("file", state.selectedPath);
  }

  const expandedPaths = normalizeWorkspacePaths(state.expandedPaths ?? []);
  openTabs = normalizeOpenTabs(openTabs, activeTab);

  if (activeTab) {
    const normalizedActive = makeTab(activeTab.kind, activeTab.path);
    if (!openTabs.some((tab) => tabsEqual(tab, normalizedActive))) {
      openTabs = [normalizedActive, ...openTabs];
    }
    activeTab = normalizedActive;
  }

  return {
    activeTab,
    openTabs,
    expandedPaths,
  };
}

export const useWorkspaceStore = create<WorkspaceUiState>()(
  persist(
    (set, get) => ({
      activeTab: null,
      openTabs: [],
      expandedPaths: [],
      treeFilter: "",
      pathsReconciled: false,
      setPathsReconciled: (ready) => set({ pathsReconciled: ready }),

      openTab: (tab) => {
        const normalized = makeTab(tab.kind, tab.path);
        const { openTabs } = get();
        const exists = openTabs.some((item) => tabsEqual(item, normalized));
        set({
          activeTab: normalized,
          openTabs: exists ? openTabs : [...openTabs, normalized],
        });
      },

      openFile: (path) => {
        get().openTab(makeTab("file", path));
      },

      openFolder: (path) => {
        get().openTab(makeTab("folder", path));
      },

      closeTab: (tab) => {
        const normalized = makeTab(tab.kind, tab.path);
        const { openTabs, activeTab } = get();
        const nextOpen = openTabs.filter((item) => !tabsEqual(item, normalized));
        let nextActive = activeTab;
        if (activeTab && tabsEqual(activeTab, normalized)) {
          const closedIndex = openTabs.findIndex((item) => tabsEqual(item, normalized));
          nextActive = nextOpen[Math.min(closedIndex, nextOpen.length - 1)] ?? null;
        }
        set({ openTabs: nextOpen, activeTab: nextActive });
      },

      selectTab: (tab) => {
        get().openTab(tab);
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

      isTabActive: (tab) => tabsEqual(get().activeTab, makeTab(tab.kind, tab.path)),
    }),
    {
      name: "kew-workspace-ui",
      version: 3,
      partialize: (state) => ({
        expandedPaths: state.expandedPaths,
        activeTab: state.activeTab,
        openTabs: state.openTabs,
      }),
      migrate: (persisted, version) => {
        if (version < 3) {
          return {
            ...(persisted as object),
            ...normalizePersistedState(persisted as LegacyPersistedState),
          };
        }
        return persisted;
      },
      merge: (persisted, current) => {
        const merged = {
          ...current,
          ...normalizePersistedState(persisted as LegacyPersistedState),
        };
        merged.openTabs = normalizeOpenTabs(merged.openTabs ?? [], merged.activeTab ?? null);
        return merged;
      },
    },
  ),
);
