import { create } from "zustand";

import type { ChangePlan, ChatMode } from "@/shared/types/chat";

function defaultAcceptedHunks(plan: ChangePlan | null): Record<string, boolean> {
  if (!plan) {
    return {};
  }
  const units = plan.hunks.length > 0 ? plan.hunks : plan.sections;
  return Object.fromEntries(units.map((unit) => [unit.id, false]));
}

interface ChatState {
  conversationId: string | null;
  conversationScope: string | null;
  chatMode: ChatMode;
  pendingPlan: ChangePlan | null;
  acceptedHunkIds: Record<string, boolean>;
  setConversationId: (id: string | null) => void;
  setConversationScope: (scope: string | null) => void;
  setChatMode: (mode: ChatMode) => void;
  setPendingPlan: (plan: ChangePlan | null) => void;
  setHunkAccepted: (hunkId: string, accepted: boolean) => void;
  toggleHunk: (hunkId: string) => void;
  acceptAllHunks: () => void;
  rejectAllHunks: () => void;
  getAcceptedHunkIdList: () => string[];
  reset: () => void;
}

export const useChatStore = create<ChatState>((set, get) => ({
  conversationId: null,
  conversationScope: null,
  chatMode: "agent",
  pendingPlan: null,
  acceptedHunkIds: {},
  setConversationId: (conversationId) => set({ conversationId }),
  setConversationScope: (conversationScope) => set({ conversationScope }),
  setChatMode: (chatMode) => set({ chatMode }),
  setPendingPlan: (pendingPlan) =>
    set({
      pendingPlan,
      acceptedHunkIds: defaultAcceptedHunks(pendingPlan),
    }),
  setHunkAccepted: (hunkId, accepted) =>
    set((state) => ({
      acceptedHunkIds: { ...state.acceptedHunkIds, [hunkId]: accepted },
    })),
  toggleHunk: (hunkId) =>
    set((state) => ({
      acceptedHunkIds: {
        ...state.acceptedHunkIds,
        [hunkId]: !state.acceptedHunkIds[hunkId],
      },
    })),
  acceptAllHunks: () => {
    const plan = get().pendingPlan;
    if (!plan) {
      return;
    }
    const units = plan.hunks.length > 0 ? plan.hunks : plan.sections;
    set({
      acceptedHunkIds: Object.fromEntries(units.map((unit) => [unit.id, true])),
    });
  },
  rejectAllHunks: () => {
    const plan = get().pendingPlan;
    if (!plan) {
      return;
    }
    const units = plan.hunks.length > 0 ? plan.hunks : plan.sections;
    set({
      acceptedHunkIds: Object.fromEntries(units.map((unit) => [unit.id, false])),
    });
  },
  getAcceptedHunkIdList: () =>
    Object.entries(get().acceptedHunkIds)
      .filter(([, accepted]) => accepted)
      .map(([id]) => id),
  reset: () =>
    set({
      conversationId: null,
      conversationScope: null,
      pendingPlan: null,
      acceptedHunkIds: {},
    }),
}));
