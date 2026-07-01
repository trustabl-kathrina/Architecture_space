import { useEffect, useRef } from "react";

import { AssistantMessage } from "@/features/ai/components/AssistantMessage";
import { ExecutionTrailPanel } from "@/features/ai/components/ExecutionTrailPanel";
import { UserMessageBubble } from "@/features/ai/components/UserMessageBubble";
import type { ChatMessage, StreamingTurn } from "@/shared/types/chat";

interface ChatMessageListProps {
  messages: ChatMessage[];
  streamingTurn?: StreamingTurn | null;
  isSending?: boolean;
  onEditMessage?: (messageId: string, content: string) => void;
  onDeleteMessage?: (messageId: string) => void;
}

export function ChatMessageList({
  messages,
  streamingTurn,
  isSending = false,
  onEditMessage,
  onDeleteMessage,
}: ChatMessageListProps) {
  const bottomRef = useRef<HTMLDivElement>(null);
  const isStreaming = Boolean(streamingTurn);

  useEffect(() => {
    bottomRef.current?.scrollIntoView({ behavior: "smooth" });
  }, [messages, streamingTurn]);

  if (messages.length === 0 && !isStreaming) {
    return (
      <div className="flex flex-1 flex-col items-center justify-center px-6 text-center">
        <div className="mb-3 flex h-10 w-10 items-center justify-center rounded-full bg-surface-overlay">
          <svg width="20" height="20" viewBox="0 0 24 24" fill="none" aria-hidden className="text-content-subtle">
            <path
              d="M12 3C7.03 3 3 6.58 3 11c0 2.03.9 3.88 2.36 5.24L4 21l4.2-1.2C9.4 20.26 10.66 20.5 12 20.5c4.97 0 9-3.58 9-8s-4.03-8-9-8z"
              stroke="currentColor"
              strokeWidth="1.5"
              strokeLinejoin="round"
            />
          </svg>
        </div>
        <p className="mb-1 text-sm font-medium text-content">How can I help?</p>
        <p className="max-w-[260px] text-xs leading-relaxed text-content-subtle">
          Plan and Agent mode share one chat per file or folder. Edit or delete a message to reset
          context from that point.
        </p>
      </div>
    );
  }

  return (
    <div className="flex-1 overflow-y-auto px-4 py-4">
      <div className="mx-auto flex max-w-2xl flex-col gap-5">
        {messages.map((message) => {
          if (message.role === "user") {
            return (
              <div key={message.id} className="flex justify-end">
                <UserMessageBubble
                  message={message}
                  disabled={isSending || !onEditMessage || !onDeleteMessage}
                  onEdit={onEditMessage ?? (() => undefined)}
                  onDelete={onDeleteMessage ?? (() => undefined)}
                />
              </div>
            );
          }

          return (
            <div key={message.id} className="flex flex-col items-start gap-1">
              {message.executionTrail && message.executionTrail.length > 0 ? (
                <ExecutionTrailPanel trail={message.executionTrail} />
              ) : null}
              <AssistantMessage content={message.content} />
            </div>
          );
        })}

        {streamingTurn ? (
          <>
            <div className="flex justify-end">
              <div className="max-w-[85%] rounded-2xl bg-surface-overlay px-4 py-2.5 text-sm leading-relaxed text-content">
                <p className="whitespace-pre-wrap">{streamingTurn.userText}</p>
              </div>
            </div>

            <div className="flex flex-col items-start gap-1">
              <ExecutionTrailPanel
                trail={streamingTurn.trail}
                agentThoughts={streamingTurn.agentThoughts}
                statusLine={streamingTurn.status}
                error={streamingTurn.error}
                isLive={!streamingTurn.failed}
                defaultOpen
              />
              {!streamingTurn.failed ? (
                <AssistantMessage content={streamingTurn.assistantText} isStreaming />
              ) : null}
            </div>
          </>
        ) : null}

        <div ref={bottomRef} />
      </div>
    </div>
  );
}
