import { useState } from "react";

import type { ChatMessage } from "@/shared/types/chat";
import { cn } from "@/shared/utils/cn";

interface UserMessageBubbleProps {
  message: ChatMessage;
  disabled?: boolean;
  onEdit: (messageId: string, content: string) => void;
  onDelete: (messageId: string) => void;
}

export function UserMessageBubble({
  message,
  disabled = false,
  onEdit,
  onDelete,
}: UserMessageBubbleProps) {
  const [isEditing, setIsEditing] = useState(false);
  const [draft, setDraft] = useState(message.content);

  const handleSave = () => {
    const trimmed = draft.trim();
    if (!trimmed || trimmed === message.content) {
      setIsEditing(false);
      setDraft(message.content);
      return;
    }
    setIsEditing(false);
    onEdit(message.id, trimmed);
  };

  const handleCancel = () => {
    setDraft(message.content);
    setIsEditing(false);
  };

  return (
    <div className="group flex max-w-[85%] flex-col items-end gap-1.5">
      {isEditing ? (
        <div className="w-full min-w-[220px] rounded-2xl border border-border/60 bg-surface-overlay p-3">
          <textarea
            value={draft}
            onChange={(event) => setDraft(event.target.value)}
            className="min-h-[72px] w-full resize-y bg-transparent text-sm leading-relaxed text-content focus:outline-none"
            autoFocus
          />
          <div className="mt-2 flex justify-end gap-2">
            <button
              type="button"
              onClick={handleCancel}
              className="rounded-lg px-2.5 py-1 text-xs text-content-muted hover:bg-surface/80"
            >
              Cancel
            </button>
            <button
              type="button"
              onClick={handleSave}
              disabled={!draft.trim()}
              className="rounded-lg bg-accent px-2.5 py-1 text-xs font-medium text-white disabled:opacity-50"
            >
              Save & regenerate
            </button>
          </div>
        </div>
      ) : (
        <>
          {message.chatMode ? (
            <span className="text-[10px] font-medium uppercase tracking-wide text-content-subtle">
              {message.chatMode === "plan" ? "Plan" : "Agent"}
            </span>
          ) : null}
          <div className="rounded-2xl bg-surface-overlay px-4 py-2.5 text-sm leading-relaxed text-content">
            <p className="whitespace-pre-wrap">{message.content}</p>
          </div>
          <div
            className={cn(
              "flex gap-2 opacity-0 transition-opacity group-hover:opacity-100",
              disabled && "pointer-events-none opacity-40",
            )}
          >
            <button
              type="button"
              onClick={() => setIsEditing(true)}
              className="text-[11px] text-content-subtle hover:text-content"
            >
              Edit
            </button>
            <button
              type="button"
              onClick={() => onDelete(message.id)}
              className="text-[11px] text-content-subtle hover:text-red-400"
            >
              Delete
            </button>
          </div>
        </>
      )}
    </div>
  );
}
