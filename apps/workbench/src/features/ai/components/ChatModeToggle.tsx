import type { ChatMode } from "@/shared/types/chat";
import { cn } from "@/shared/utils/cn";

interface ChatModeToggleProps {
  mode: ChatMode;
  onChange: (mode: ChatMode) => void;
  disabled?: boolean;
}

const MODES: { id: ChatMode; label: string; hint: string }[] = [
  {
    id: "plan",
    label: "Plan",
    hint: "Structure, outline, and advise without editing files",
  },
  {
    id: "agent",
    label: "Agent",
    hint: "Full agent workflow with approval-gated edits",
  },
];

export function ChatModeToggle({ mode, onChange, disabled }: ChatModeToggleProps) {
  return (
    <div
      className="flex rounded-lg border border-border/60 bg-surface p-0.5"
      role="group"
      aria-label="Chat mode"
    >
      {MODES.map((item) => {
        const isActive = mode === item.id;
        return (
          <button
            key={item.id}
            type="button"
            disabled={disabled}
            title={item.hint}
            aria-pressed={isActive}
            onClick={() => onChange(item.id)}
            className={cn(
              "rounded-md px-2.5 py-1 text-[11px] font-medium transition-colors",
              isActive
                ? "bg-surface-overlay text-content shadow-sm"
                : "text-content-muted hover:text-content",
              disabled && "cursor-not-allowed opacity-50",
            )}
          >
            {item.label}
          </button>
        );
      })}
    </div>
  );
}
