import { useQuery, useQueryClient } from "@tanstack/react-query";
import { useCallback, useEffect, useMemo, useState } from "react";

import {
  chatKeys,
  clearConversation,
  deleteMessage,
  editMessage,
  fetchConversation,
  resolveConversation,
} from "@/features/ai/api/chatApi";
import { streamChatMessage, streamRegenerateMessage } from "@/features/ai/api/chatStreamApi";
import { formatChatError } from "@/features/ai/lib/formatChatError";
import { useChangeReview } from "@/features/ai/hooks/useChangeReview";
import { mergeExecutionPlan, upsertTrailStep, appendAgentThought } from "@/features/ai/lib/trailUtils";
import { useChatStore } from "@/features/ai/stores/chatStore";
import {
  extractDocumentOutline,
  inferActiveSection,
} from "@/features/editor/lib/documentOutline";
import { useEditorStore } from "@/features/editor/stores/editorStore";
import { fetchTree, workspaceKeys } from "@/features/workspace/api/workspaceApi";
import { useFolderPlanStore } from "@/features/workspace/stores/folderPlanStore";
import { composePlanTextarea, mergeAiPlanIntoDraft } from "@/features/workspace/lib/composePlanTextarea";
import { useWorkspaceStore } from "@/features/workspace/stores/workspaceStore";
import type {
  ChatMode,
  ChatStreamEvent,
  Conversation,
  RegenerateMessageRequest,
  SendMessageRequest,
  StreamingTurn,
} from "@/shared/types/chat";
import { tabKey, type WorkbenchTab } from "@/shared/types/workspace";

function conversationScopeForTab(tab: WorkbenchTab | null): string | null {
  if (!tab) {
    return null;
  }
  return tabKey(tab);
}

function isChatEnabled(tab: WorkbenchTab | null): boolean {
  if (!tab) {
    return false;
  }
  if (tab.kind === "folder") {
    return true;
  }
  return tab.path.toLowerCase().endsWith(".md");
}

export function useChat(activeTab: WorkbenchTab | null) {
  const queryClient = useQueryClient();
  const conversationId = useChatStore((s) => s.conversationId);
  const conversationScope = useChatStore((s) => s.conversationScope);
  const chatMode = useChatStore((s) => s.chatMode);
  const pendingPlan = useChatStore((s) => s.pendingPlan);
  const setConversationId = useChatStore((s) => s.setConversationId);
  const setConversationScope = useChatStore((s) => s.setConversationScope);
  const setPendingPlan = useChatStore((s) => s.setPendingPlan);
  const getDraft = useEditorStore((s) => s.getDraft);
  const openTabs = useWorkspaceStore((s) => s.openTabs);
  const getFolderPlan = useFolderPlanStore((s) => s.getPlan);
  const getLastAiPlan = useFolderPlanStore((s) => s.getLastAiPlan);
  const setFolderPlan = useFolderPlanStore((s) => s.setPlan);
  const setLastAiPlan = useFolderPlanStore((s) => s.setLastAiPlan);

  const scopeKey = conversationScopeForTab(activeTab);
  const documentPath = activeTab?.kind === "file" ? activeTab.path : null;
  const isFolderTab = activeTab?.kind === "folder";
  const folderPath = isFolderTab ? activeTab.path : null;

  const changeReview = useChangeReview(documentPath);

  const [initError, setInitError] = useState<string | null>(null);
  const [streamingTurn, setStreamingTurn] = useState<StreamingTurn | null>(null);
  const [sendError, setSendError] = useState<string | null>(null);
  const [isSending, setIsSending] = useState(false);

  const enabled = isChatEnabled(activeTab);

  const folderContentsQuery = useQuery({
    queryKey: workspaceKeys.tree(folderPath ?? "__none__", 1),
    queryFn: () => fetchTree(folderPath ?? "", 1),
    enabled: isFolderTab,
    staleTime: 30_000,
  });

  useEffect(() => {
    if (!enabled || !activeTab) {
      setConversationId(null);
      setConversationScope(null);
      setPendingPlan(null);
      setInitError(null);
      setStreamingTurn(null);
      setSendError(null);
      setIsSending(false);
      return;
    }

    if (conversationId && conversationScope === scopeKey) {
      return;
    }

    let cancelled = false;
    setInitError(null);

    void (async () => {
      try {
        const conversation = await resolveConversation({
          scopeKind: activeTab.kind,
          scopePath: activeTab.path,
          chatMode,
        });
        if (!cancelled) {
          setConversationId(conversation.id);
          setConversationScope(scopeKey);
          setPendingPlan(null);
          queryClient.setQueryData(chatKeys.conversation(conversation.id), conversation);
        }
      } catch (error) {
        if (!cancelled) {
          setInitError(error instanceof Error ? error.message : "Failed to load chat history");
        }
      }
    })();

    return () => {
      cancelled = true;
    };
  }, [
    activeTab,
    enabled,
    conversationId,
    conversationScope,
    scopeKey,
    queryClient,
    setConversationId,
    setConversationScope,
    setPendingPlan,
  ]);

  const conversationQuery = useQuery({
    queryKey: chatKeys.conversation(conversationId ?? ""),
    queryFn: () => fetchConversation(conversationId!),
    enabled: Boolean(conversationId),
  });

  const openPaths = useMemo(
    () => openTabs.filter((tab) => tab.kind === "file").map((tab) => tab.path),
    [openTabs],
  );

  const buildMessageContext = useCallback(
    (content: string) => {
      const draft = documentPath ? getDraft(documentPath) : undefined;
      const body = draft?.draftBody ?? "";
      const activeSection = documentPath ? inferActiveSection(body, content) : null;
      const documentOutline = documentPath ? extractDocumentOutline(body) : [];
      const folderPlan = isFolderTab && folderPath !== null ? getFolderPlan(folderPath) : null;
      const folderContents =
        folderContentsQuery.data?.nodes.map((node) => `${node.type}:${node.path}`) ?? [];

      const request: SendMessageRequest = {
        content,
        documentPath,
        folderPath,
        folderPlan,
        folderContents,
        chatMode,
        openPaths,
        activeSection,
        documentOutline,
      };
      const regenerateRequest: RegenerateMessageRequest = {
        documentPath,
        folderPath,
        folderPlan,
        folderContents,
        chatMode,
        openPaths,
        activeSection,
        documentOutline,
      };
      return { request, regenerateRequest };
    },
    [
      documentPath,
      folderPath,
      getDraft,
      getFolderPlan,
      folderContentsQuery.data?.nodes,
      chatMode,
      isFolderTab,
      openPaths,
    ],
  );

  const applyFolderPlanResult = useCallback(
    (folderPlanResult: NonNullable<NonNullable<ChatStreamEvent["response"]>["folderPlanResult"]>) => {
      if (!isFolderTab || folderPath === null) {
        return;
      }
      const newAiPlan = composePlanTextarea(folderPlanResult);
      const currentPlan = getFolderPlan(folderPath);
      const { merged, lastAiPlan } = mergeAiPlanIntoDraft(
        currentPlan,
        getLastAiPlan(folderPath),
        newAiPlan,
      );
      setFolderPlan(folderPath, merged);
      setLastAiPlan(folderPath, lastAiPlan);
    },
    [folderPath, getFolderPlan, getLastAiPlan, isFolderTab, setFolderPlan, setLastAiPlan],
  );

  const handleStreamEvent = useCallback(
    (
      event: ChatStreamEvent,
      state: { completed: boolean; userText: string },
    ): boolean => {
      switch (event.type) {
        case "status":
          setStreamingTurn((current) =>
            current ? { ...current, status: event.message ?? current.status } : current,
          );
          break;
        case "execution_plan":
          if (event.steps) {
            setStreamingTurn((current) =>
              current
                ? { ...current, trail: mergeExecutionPlan(current.trail, event.steps!) }
                : current,
            );
          }
          break;
        case "trail_step":
          if (event.step) {
            setStreamingTurn((current) =>
              current
                ? { ...current, trail: upsertTrailStep(current.trail, event.step!) }
                : current,
            );
          }
          break;
        case "agent_thought":
          if (event.agent && event.content) {
            setStreamingTurn((current) =>
              current
                ? {
                    ...current,
                    agentThoughts: appendAgentThought(
                      current.agentThoughts,
                      event.agent!,
                      event.content!,
                    ),
                  }
                : current,
            );
          }
          break;
        case "assistant_delta":
          setStreamingTurn((current) =>
            current
              ? {
                  ...current,
                  assistantText: current.assistantText + (event.content ?? ""),
                  status: null,
                }
              : current,
          );
          break;
        case "done":
          state.completed = true;
          if (event.response && conversationId) {
            const response = event.response;
            setPendingPlan(response.changePlan);
                if (response.folderPlanResult) {
                  applyFolderPlanResult(response.folderPlanResult);
                }
                if (response.folderImplementResult) {
                  void queryClient.invalidateQueries({ queryKey: workspaceKeys.all });
                }
                if (activeTab) {
                  void queryClient.invalidateQueries({
                    queryKey: chatKeys.sectionContext(activeTab.kind, activeTab.path),
                  });
                }
                queryClient.setQueryData<Conversation>(
              chatKeys.conversation(conversationId),
              (current) => {
                if (!current) {
                  return current;
                }
                const nextMessages = [...current.messages];
                if (response.userMessage) {
                  nextMessages.push(response.userMessage);
                }
                nextMessages.push(response.message);
                return {
                  ...current,
                  messages: nextMessages,
                  updatedAt: response.message.timestamp,
                };
              },
            );
          }
          setStreamingTurn(null);
          setIsSending(false);
          break;
        case "error":
          if (!state.completed) {
            const message = formatChatError(new Error(event.message ?? "Chat failed"));
            setStreamingTurn((current) =>
              current
                ? { ...current, error: message, failed: true, status: null }
                : current,
            );
            setIsSending(false);
          }
          break;
        default:
          break;
      }
      return state.completed;
    },
    [activeTab, applyFolderPlanResult, conversationId, queryClient, setPendingPlan],
  );

  const runStream = useCallback(
    async (
      userText: string,
      streamFn: (onEvent: (event: ChatStreamEvent) => void) => Promise<void>,
    ) => {
      if (!conversationId || !userText.trim()) {
        return;
      }

      setSendError(null);
      setIsSending(true);
      setStreamingTurn({
        userText,
        status: "Connecting…",
        trail: [],
        agentThoughts: [],
        assistantText: "",
      });

      const state = { completed: false, userText };
      try {
        await streamFn((event) => {
          handleStreamEvent(event, state);
        });
      } catch (error) {
        if (!state.completed) {
          const message = formatChatError(error);
          setStreamingTurn((current) =>
            current
              ? { ...current, error: message, failed: true, status: null }
              : current,
          );
          setIsSending(false);
        }
      } finally {
        if (!state.completed) {
          setIsSending(false);
        }
      }
    },
    [conversationId, handleStreamEvent],
  );

  const sendMessage = useCallback(
    async (content: string) => {
      const trimmed = content.trim();
      if (!conversationId || !trimmed) {
        return;
      }
      const { request } = buildMessageContext(trimmed);
      await runStream(trimmed, (onEvent) => streamChatMessage(conversationId, request, onEvent));
    },
    [buildMessageContext, conversationId, runStream],
  );

  const editMessageAndRegenerate = useCallback(
    async (messageId: string, content: string) => {
      if (!conversationId) {
        return;
      }
      const trimmed = content.trim();
      if (!trimmed) {
        return;
      }

      try {
        const updated = await editMessage(conversationId, messageId, trimmed);
        queryClient.setQueryData(chatKeys.conversation(conversationId), updated);
        const { regenerateRequest } = buildMessageContext(trimmed);
        await runStream(trimmed, (onEvent) =>
          streamRegenerateMessage(conversationId, messageId, regenerateRequest, onEvent),
        );
      } catch (error) {
        setSendError(formatChatError(error));
      }
    },
    [buildMessageContext, conversationId, queryClient, runStream],
  );

  const deleteMessageAndAfter = useCallback(
    async (messageId: string) => {
      if (!conversationId) {
        return;
      }
      try {
        const updated = await deleteMessage(conversationId, messageId);
        queryClient.setQueryData(chatKeys.conversation(conversationId), updated);
        setPendingPlan(null);
      } catch (error) {
        setSendError(formatChatError(error));
      }
    },
    [conversationId, queryClient, setPendingPlan],
  );

  const clearChat = useCallback(async () => {
    if (!conversationId) {
      return;
    }
    try {
      const cleared = await clearConversation(conversationId);
      queryClient.setQueryData(chatKeys.conversation(conversationId), cleared);
      setPendingPlan(null);
      setStreamingTurn(null);
      setSendError(null);
    } catch (error) {
      setSendError(formatChatError(error));
    }
  }, [conversationId, queryClient, setPendingPlan]);

  const messages = useMemo(
    () => conversationQuery.data?.messages ?? [],
    [conversationQuery.data?.messages],
  );

  return {
    enabled,
    conversationId,
    messages,
    isLoadingConversation: conversationQuery.isLoading,
    pendingPlan,
    isSending,
    streamingTurn,
    initError,
    sendError: streamingTurn?.error ?? sendError,
    sendMessage,
    editMessageAndRegenerate,
    deleteMessageAndAfter,
    clearChat,
    changeReview,
  };
}
