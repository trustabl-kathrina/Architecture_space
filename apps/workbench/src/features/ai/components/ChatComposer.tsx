import { useState, type CSSProperties, type FormEvent, type KeyboardEvent } from "react";

import { cn } from "@/shared/utils/cn";

interface ChatComposerProps {
  disabled: boolean;
  isSending: boolean;
  onSend: (content: string) => void;
}

export function ChatComposer({ disabled, isSending, onSend }: ChatComposerProps) {
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
          placeholder={
            disabled ? "Open a Markdown document to chat" : "Message assistant…"
          }
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
        Enter to send · Shift+Enter for new line
      </p>
    </form>
  );
}
