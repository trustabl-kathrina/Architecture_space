import { useWorkspaceStore } from "@/features/workspace/stores/workspaceStore";
import { useEditorTabs } from "@/features/editor/hooks/useEditorTabs";
import { tabKey, type WorkbenchTab } from "@/shared/types/workspace";
import { cn } from "@/shared/utils/cn";

function tabLabel(tab: WorkbenchTab): string {
  const name = tab.path.split("/").pop() || tab.path || "docs";
  return tab.kind === "folder" ? name : name;
}

export function EditorTabBar() {
  const openTabs = useWorkspaceStore((s) => s.openTabs);
  const activeTab = useWorkspaceStore((s) => s.activeTab);
  const selectTab = useWorkspaceStore((s) => s.selectTab);
  const { closeTab, dirtyPaths } = useEditorTabs();

  if (openTabs.length === 0) {
    return null;
  }

  return (
    <div
      className="flex shrink-0 gap-0.5 overflow-x-auto border-b border-border/50 bg-surface-raised/40 px-2 pt-1"
      role="tablist"
      aria-label="Open tabs"
    >
      {openTabs.map((tab) => {
        const label = tabLabel(tab);
        const isActive =
          activeTab?.kind === tab.kind && activeTab.path === tab.path;
        const isDirty = tab.kind === "file" && dirtyPaths.has(tab.path);

        return (
          <div
            key={tabKey(tab)}
            role="tab"
            aria-selected={isActive}
            className={cn(
              "group flex max-w-[240px] shrink-0 items-center gap-1 rounded-t-lg border border-b-0 px-2.5 py-1.5 text-xs transition-colors",
              isActive
                ? "border-border/60 bg-surface text-content"
                : "border-transparent text-content-muted hover:bg-surface-overlay/50 hover:text-content",
            )}
          >
            <span
              className={cn(
                "flex h-4 w-4 shrink-0 items-center justify-center text-content-subtle",
                tab.kind === "folder" && "text-amber-500/80",
              )}
              aria-hidden
            >
              {tab.kind === "folder" ? <FolderTabIcon /> : <FileTabIcon />}
            </span>
            <button
              type="button"
              className="min-w-0 flex-1 truncate text-left"
              onClick={() => selectTab(tab)}
              title={tab.path}
            >
              {isDirty ? `${label} •` : label}
            </button>
            <button
              type="button"
              className={cn(
                "flex h-5 w-5 shrink-0 items-center justify-center rounded-md text-content-subtle transition-colors",
                "opacity-0 hover:bg-surface-overlay hover:text-content group-hover:opacity-100",
                isActive && "opacity-100",
              )}
              aria-label={`Close ${label}`}
              onClick={(event) => {
                event.stopPropagation();
                void closeTab(tab);
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

function FileTabIcon() {
  return (
    <svg width="11" height="11" viewBox="0 0 12 12" fill="none" aria-hidden>
      <path
        d="M3.5 1.5h3l2.5 2.5v6.5h-5.5v-9z"
        stroke="currentColor"
        strokeWidth="1.2"
        strokeLinejoin="round"
      />
    </svg>
  );
}

function FolderTabIcon() {
  return (
    <svg width="11" height="11" viewBox="0 0 12 12" fill="none" aria-hidden>
      <path
        d="M1.5 3h3.2l1 1.2H10.5V9.5H1.5V3z"
        stroke="currentColor"
        strokeWidth="1.2"
        strokeLinejoin="round"
      />
    </svg>
  );
}
