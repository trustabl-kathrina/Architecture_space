import { create } from "zustand";
import { persist } from "zustand/middleware";

import { normalizeWorkspacePath } from "@/features/workspace/lib/pathMigration";

interface FolderPlanState {
  plansByPath: Record<string, string>;
  lastAiPlansByPath: Record<string, string>;
  getPlan: (path: string) => string;
  getLastAiPlan: (path: string) => string;
  setPlan: (path: string, content: string) => void;
  setLastAiPlan: (path: string, content: string) => void;
  clearPlan: (path: string) => void;
}

export const useFolderPlanStore = create<FolderPlanState>()(
  persist(
    (set, get) => ({
      plansByPath: {},
      lastAiPlansByPath: {},
      getPlan: (path) => {
        const normalized = normalizeWorkspacePath(path);
        return get().plansByPath[normalized] ?? "";
      },
      getLastAiPlan: (path) => {
        const normalized = normalizeWorkspacePath(path);
        return get().lastAiPlansByPath[normalized] ?? "";
      },
      setPlan: (path, content) => {
        const normalized = normalizeWorkspacePath(path);
        set((state) => ({
          plansByPath: { ...state.plansByPath, [normalized]: content },
        }));
      },
      setLastAiPlan: (path, content) => {
        const normalized = normalizeWorkspacePath(path);
        set((state) => ({
          lastAiPlansByPath: { ...state.lastAiPlansByPath, [normalized]: content },
        }));
      },
      clearPlan: (path) => {
        const normalized = normalizeWorkspacePath(path);
        set((state) => {
          const next = { ...state.plansByPath };
          const nextAi = { ...state.lastAiPlansByPath };
          delete next[normalized];
          delete nextAi[normalized];
          return { plansByPath: next, lastAiPlansByPath: nextAi };
        });
      },
    }),
    {
      name: "kew-folder-plans",
      version: 2,
      partialize: (state) => ({
        plansByPath: state.plansByPath,
        lastAiPlansByPath: state.lastAiPlansByPath,
      }),
    },
  ),
);
