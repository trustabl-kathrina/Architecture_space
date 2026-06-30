import { useState, type CSSProperties, type FormEvent, type KeyboardEvent } from "react";

import type { ChatMode } from "@/shared/types/chat";
import type { TabKind } from "@/shared/types/workspace";
import { cn } from "@/shared/utils/cn";

interface ChatComposerProps {
  disabled: boolean;
  isSending: boolean;
  chatMode: ChatMode;
  activeTabKind: TabKind | null;
  onSend: (content: string) => void;
}

function placeholderFor(chatMode: ChatMode, activeTabKind: TabKind | null, disabled: boolean): string {
  if (disabled) {
    return "Open a document or folder to chat";
  }
  if (activeTabKind === "folder") {
    return chatMode === "plan"
      ? "Plan folder structure, topics, and gaps…"
      : "Implement the plan — reorganize, scaffold files, or edit open docs…";
  }
  return chatMode === "plan"
    ? "Plan structure, outline, or strategy…"
    : "Message assistant — agent can propose edits…";
}

export function ChatComposer({
  disabled,
  isSending,
  chatMode,
  activeTabKind,
  onSend,
}: ChatComposerProps) {
  const [draft, setDraft] = useState("");

  const submit = () => {
    const trimmed = draft.trim();
    if (!trimmed || disabled || isSending) {
      return;
    }
    onSend(trimmed);
    setDraft("");
  };

  const handleSubmit = (event: FormEvent) => {
    event.preventDefault();
    submit();
  };

  const handleKeyDown = (event: KeyboardEvent<HTMLTextAreaElement>) => {
    if (event.key === "Enter" && !event.shiftKey) {
      event.preventDefault();
      submit();
    }
  };

  const canSend = !disabled && !isSending && draft.trim().length > 0;

  return (
    <form onSubmit={handleSubmit} className="shrink-0 px-4 pb-4 pt-2">
      <div
        className={cn(
          "flex items-end gap-2 rounded-3xl border border-border/60 bg-surface-input px-3 py-2 shadow-sm",
          "focus-within:border-border-strong focus-within:ring-1 focus-within:ring-border-strong/50",
          disabled && "opacity-50",
        )}
      >
        <textarea
          value={draft}
          onChange={(event) => setDraft(event.target.value)}
          onKeyDown={handleKeyDown}
          placeholder={placeholderFor(chatMode, activeTabKind, disabled)}
          disabled={disabled || isSending}
          rows={1}
          className="max-h-32 min-h-[24px] flex-1 resize-none bg-transparent py-1.5 text-sm leading-relaxed text-content placeholder:text-content-subtle focus:outline-none disabled:cursor-not-allowed"
          style={{ fieldSizing: "content" } as CSSProperties}
        />
        <button
          type="submit"
          disabled={!canSend}
          aria-label={isSending ? "Sending" : "Send message"}
          className={cn(
            "mb-0.5 flex h-8 w-8 shrink-0 items-center justify-center rounded-full transition-colors",
            canSend
              ? "bg-accent text-white hover:bg-accent-hover"
              : "bg-surface-overlay text-content-subtle",
          )}
        >
          {isSending ? (
            <span className="h-4 w-4 animate-spin rounded-full border-2 border-white/30 border-t-white" />
          ) : (
            <svg width="16" height="16" viewBox="0 0 16 16" fill="none" aria-hidden>
              <path
                d="M8 13V3M8 3L4 7M8 3L12 7"
                stroke="currentColor"
                strokeWidth="1.75"
                strokeLinecap="round"
                strokeLinejoin="round"
              />
            </svg>
          )}
        </button>
      </div>
      <p className="mt-2 text-center text-[11px] text-content-subtle">
        {chatMode === "plan" ? "Plan mode — structure & lineage" : "Agent mode — implement with approval"} · Enter to send
      </p>
    </form>
  );
}
