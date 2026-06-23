import { useWorkspaceStore } from "@/features/workspace/stores/workspaceStore";
import { useEditorTabs } from "@/features/editor/hooks/useEditorTabs";
import { cn } from "@/shared/utils/cn";

export function EditorTabBar() {
  const openPaths = useWorkspaceStore((s) => s.openPaths);
  const selectedPath = useWorkspaceStore((s) => s.selectedPath);
  const setSelectedPath = useWorkspaceStore((s) => s.setSelectedPath);
  const { closeTab, dirtyPaths } = useEditorTabs();

  if (openPaths.length === 0) {
    return null;
  }

  return (
    <div
      className="flex shrink-0 gap-0.5 overflow-x-auto border-b border-border/50 bg-surface-raised/40 px-2 pt-1"
      role="tablist"
      aria-label="Open documents"
    >
      {openPaths.map((path) => {
        const fileName = path.split("/").pop() ?? path;
        const isActive = path === selectedPath;
        const isDirty = dirtyPaths.has(path);

        return (
          <div
            key={path}
            role="tab"
            aria-selected={isActive}
            className={cn(
              "group flex max-w-[220px] shrink-0 items-center gap-1 rounded-t-lg border border-b-0 px-2.5 py-1.5 text-xs transition-colors",
              isActive
                ? "border-border/60 bg-surface text-content"
                : "border-transparent text-content-muted hover:bg-surface-overlay/50 hover:text-content",
            )}
          >
            <button
              type="button"
              className="min-w-0 flex-1 truncate text-left"
              onClick={() => setSelectedPath(path)}
              title={path}
            >
              {isDirty ? `${fileName} •` : fileName}
            </button>
            <button
              type="button"
              className={cn(
                "flex h-5 w-5 shrink-0 items-center justify-center rounded-md text-content-subtle transition-colors",
                "opacity-0 hover:bg-surface-overlay hover:text-content group-hover:opacity-100",
                isActive && "opacity-100",
              )}
              aria-label={`Close ${fileName}`}
              onClick={(event) => {
                event.stopPropagation();
                void closeTab(path);
              }}
            >
              <svg width="10" height="10" viewBox="0 0 10 10" fill="none" aria-hidden>
                <path
                  d="M2 2L8 8M8 2L2 8"
                  stroke="currentColor"
                  strokeWidth="1.5"
                  strokeLinecap="round"
                />
              </svg>
            </button>
          </div>
        );
      })}
    </div>
  );
}
