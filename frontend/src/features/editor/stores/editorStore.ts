import { create } from "zustand";
import { persist } from "zustand/middleware";

import { joinFrontMatter, splitFrontMatter } from "@/features/editor/lib/frontMatter";
import type { EditorViewMode } from "@/shared/types/document";

export interface DocumentDraft {
  draftContent: string;
  draftBody: string;
  frontMatter: string | null;
  savedChecksum: string | null;
  isDirty: boolean;
}

interface EditorState {
  viewMode: EditorViewMode;
  draftsByPath: Record<string, DocumentDraft>;
  setViewMode: (mode: EditorViewMode) => void;
  setDraftContent: (path: string, content: string, savedChecksum?: string | null) => void;
  markSaved: (path: string, checksum: string) => void;
  clearDraft: (path: string) => void;
  getDraft: (path: string) => DocumentDraft | undefined;
}

export const useEditorStore = create<EditorState>()(
  persist(
    (set, get) => ({
      viewMode: "split",
      draftsByPath: {},
      setViewMode: (mode) => set({ viewMode: mode }),
      setDraftContent: (path, content, savedChecksum = null) => {
        const { frontMatter, body } = splitFrontMatter(content);
        set((state) => ({
          draftsByPath: {
            ...state.draftsByPath,
            [path]: {
              draftContent: content,
              draftBody: body,
              frontMatter,
              savedChecksum: savedChecksum ?? null,
              isDirty: false,
            },
          },
        }));
      },
      markSaved: (path, checksum) => {
        const draft = get().draftsByPath[path];
        if (!draft) {
          return;
        }
        set((state) => ({
          draftsByPath: {
            ...state.draftsByPath,
            [path]: { ...draft, savedChecksum: checksum, isDirty: false },
          },
        }));
      },
      clearDraft: (path) => {
        set((state) => {
          const { [path]: _removed, ...rest } = state.draftsByPath;
          return { draftsByPath: rest };
        });
      },
      getDraft: (path) => get().draftsByPath[path],
    }),
    {
      name: "kew-editor-ui",
      partialize: (state) => ({ viewMode: state.viewMode }),
    },
  ),
);

export function markEditorDirty(path: string, body: string) {
  const state = useEditorStore.getState();
  const existing = state.draftsByPath[path];
  if (!existing) {
    return;
  }

  const draftContent = joinFrontMatter(existing.frontMatter, body);
  useEditorStore.setState({
    draftsByPath: {
      ...state.draftsByPath,
      [path]: {
        ...existing,
        draftBody: body,
        draftContent,
        isDirty: true,
      },
    },
  });
}
