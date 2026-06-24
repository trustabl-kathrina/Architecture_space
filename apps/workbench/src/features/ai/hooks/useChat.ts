import { useMutation, useQuery, useQueryClient } from "@tanstack/react-query";
import { useCallback, useEffect, useMemo, useState } from "react";

import { chatKeys, createConversation, fetchConversation } from "@/features/ai/api/chatApi";
import { streamChatMessage } from "@/features/ai/api/chatStreamApi";
import { formatChatError } from "@/features/ai/lib/formatChatError";
import { useChangeReview } from "@/features/ai/hooks/useChangeReview";
import { mergeExecutionPlan, upsertTrailStep, appendAgentThought } from "@/features/ai/lib/trailUtils";
import { useChatStore } from "@/features/ai/stores/chatStore";
import {
  extractDocumentOutline,
  inferActiveSection,
} from "@/features/editor/lib/documentOutline";
import { useEditorStore } from "@/features/editor/stores/editorStore";
import { useWorkspaceStore } from "@/features/workspace/stores/workspaceStore";
import type { Conversation, StreamingTurn } from "@/shared/types/chat";

export function useChat(documentPath: string | null) {
  const queryClient = useQueryClient();
  const conversationId = useChatStore((s) => s.conversationId);
  const pendingPlan = useChatStore((s) => s.pendingPlan);
  const setConversationId = useChatStore((s) => s.setConversationId);
  const setPendingPlan = useChatStore((s) => s.setPendingPlan);
  const getDraft = useEditorStore((s) => s.getDraft);
  const openPaths = useWorkspaceStore((s) => s.openPaths);

  const changeReview = useChangeReview(documentPath);

  const [initError, setInitError] = useState<string | null>(null);
  const [streamingTurn, setStreamingTurn] = useState<StreamingTurn | null>(null);
  const [sendError, setSendError] = useState<string | null>(null);
  const [isSending, setIsSending] = useState(false);

  const enabled = Boolean(documentPath?.toLowerCase().endsWith(".md"));

  useEffect(() => {
    if (!enabled) {
      setConversationId(null);
      setPendingPlan(null);
      setInitError(null);
      setStreamingTurn(null);
      setSendError(null);
      setIsSending(false);
      return;
    }

    if (conversationId) {
      return;
    }

    let cancelled = false;
    setInitError(null);

    void (async () => {
      try {
        const conversation = await createConversation(documentPath);
        if (!cancelled) {
          setConversationId(conversation.id);
          setPendingPlan(null);
        }
      } catch (error) {
        if (!cancelled) {
          setInitError(error instanceof Error ? error.message : "Failed to start chat");
        }
      }
    })();

    return () => {
      cancelled = true;
    };
  }, [documentPath, enabled, conversationId, setConversationId, setPendingPlan]);

  const conversationQuery = useQuery({
    queryKey: chatKeys.conversation(conversationId ?? ""),
    queryFn: () => fetchConversation(conversationId!),
    enabled: Boolean(conversationId),
  });

  const sendMessage = useCallback(
    async (content: string) => {
      const trimmed = content.trim();
      if (!conversationId || !trimmed) {
        return;
      }

      const draft = documentPath ? getDraft(documentPath) : undefined;
      const body = draft?.draftBody ?? "";
      const activeSection = inferActiveSection(body, trimmed);
      const documentOutline = extractDocumentOutline(body);

      setSendError(null);
      setIsSending(true);
      setStreamingTurn({
        userText: trimmed,
        status: "Connecting…",
        trail: [],
        agentThoughts: [],
        assistantText: "",
      });

      let completed = false;
      try {
        await streamChatMessage(
          conversationId,
          {
            content: trimmed,
            documentPath,
            openPaths,
            activeSection,
            documentOutline,
          },
          (event) => {
            switch (event.type) {
              case "status":
                setStreamingTurn((current) =>
                  current
                    ? { ...current, status: event.message ?? current.status }
                    : current,
                );
                break;
              case "execution_plan":
                if (event.steps) {
                  setStreamingTurn((current) =>
                    current
                      ? {
                          ...current,
                          trail: mergeExecutionPlan(current.trail, event.steps!),
                        }
                      : current,
                  );
                }
                break;
              case "trail_step":
                if (event.step) {
                  setStreamingTurn((current) =>
                    current
                      ? {
                          ...current,
                          trail: upsertTrailStep(current.trail, event.step!),
                        }
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
                completed = true;
                if (event.response && conversationId) {
                  const response = event.response;
                  setPendingPlan(response.changePlan);
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
                if (!completed) {
                  const message = formatChatError(
                    new Error(event.message ?? "Chat failed"),
                  );
                  setStreamingTurn((current) =>
                    current
                      ? {
                          ...current,
                          error: message,
                          failed: true,
                          status: null,
                        }
                      : current,
                  );
                  setIsSending(false);
                }
                break;
              default:
                break;
            }
          },
        );
      } catch (error) {
        if (!completed) {
          const message = formatChatError(error);
          setStreamingTurn((current) =>
            current
              ? {
                  ...current,
                  error: message,
                  failed: true,
                  status: null,
                }
              : current,
          );
          setIsSending(false);
        }
      } finally {
        if (!completed) {
          setIsSending(false);
        }
      }
    },
    [
      conversationId,
      documentPath,
      getDraft,
      openPaths,
      queryClient,
      setPendingPlan,
    ],
  );

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
    changeReview,
  };
}
