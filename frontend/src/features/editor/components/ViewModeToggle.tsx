import { useEditorStore } from "@/features/editor/stores/editorStore";
import type { EditorViewMode } from "@/shared/types/document";
import { cn } from "@/shared/utils/cn";

const MODES: { id: EditorViewMode; label: string }[] = [
  { id: "edit", label: "Edit" },
  { id: "split", label: "Split" },
  { id: "preview", label: "Preview" },
];

export function ViewModeToggle() {
  const viewMode = useEditorStore((s) => s.viewMode);
  const setViewMode = useEditorStore((s) => s.setViewMode);

  return (
    <div
      className="inline-flex rounded-xl bg-surface-overlay/80 p-1"
      role="tablist"
      aria-label="Editor view mode"
    >
      {MODES.map((mode) => (
        <button
          key={mode.id}
          type="button"
          role="tab"
          aria-selected={viewMode === mode.id}
          className={cn(
            "rounded-lg px-3.5 py-1.5 text-xs font-medium transition-all",
            viewMode === mode.id
              ? "bg-surface-raised text-content shadow-sm"
              : "text-content-subtle hover:text-content-muted",
          )}
          onClick={() => setViewMode(mode.id)}
        >
          {mode.label}
        </button>
      ))}
    </div>
  );
}
