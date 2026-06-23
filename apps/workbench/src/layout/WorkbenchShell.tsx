import { Group, Panel, Separator, useDefaultLayout } from "react-resizable-panels";

import { ChatPanel } from "@/features/ai/components/ChatPanel";
import { CenterPanel } from "@/features/editor/components/CenterPanel";
import { Sidebar } from "@/features/workspace/components/Sidebar";
import { useWorkspaceBootstrap } from "@/features/workspace/hooks/useWorkspaceBootstrap";
import { useWorkspaceStore } from "@/features/workspace/stores/workspaceStore";
import { cn } from "@/shared/utils/cn";

function ResizeHandle() {
  return (
    <Separator
      className={cn(
        "resize-handle",
        "data-[separator]:active:bg-accent/30",
      )}
    />
  );
}

export function WorkbenchShell() {
  useWorkspaceBootstrap();
  const selectedPath = useWorkspaceStore((s) => s.selectedPath);
  const fileName = selectedPath?.split("/").pop();

  const { defaultLayout, onLayoutChanged } = useDefaultLayout({
    id: "kew-workbench-panels",
    panelIds: ["sidebar", "editor", "chat"],
  });

  return (
    <div className="flex h-full flex-col bg-surface-raised">
      <header className="flex h-12 shrink-0 items-center gap-4 border-b border-border/50 px-4">
        <div className="flex items-center gap-2.5">
          <div className="flex h-7 w-7 items-center justify-center rounded-lg bg-surface-overlay text-xs font-semibold text-content">
            K
          </div>
          <span className="text-sm font-medium text-content">KEW</span>
        </div>

        {fileName ? (
          <>
            <span className="text-content-subtle/40">/</span>
            <p className="min-w-0 truncate text-sm text-content-muted">{fileName}</p>
          </>
        ) : (
          <p className="text-sm text-content-subtle">Select a document</p>
        )}
      </header>

      <Group
        orientation="horizontal"
        className="min-h-0 flex-1"
        defaultLayout={defaultLayout}
        onLayoutChanged={onLayoutChanged}
      >
        <Panel id="sidebar" defaultSize="18%" minSize="14%" maxSize="30%" className="min-w-0">
          <Sidebar />
        </Panel>

        <ResizeHandle />

        <Panel id="editor" defaultSize="52%" minSize="35%" className="min-w-0 bg-surface">
          <CenterPanel />
        </Panel>

        <ResizeHandle />

        <Panel id="chat" defaultSize="30%" minSize="20%" maxSize="42%" className="min-w-0">
          <ChatPanel />
        </Panel>
      </Group>
    </div>
  );
}
