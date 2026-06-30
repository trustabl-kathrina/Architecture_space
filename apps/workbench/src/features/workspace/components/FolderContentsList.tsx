import { useQuery } from "@tanstack/react-query";

import { fetchTree, workspaceKeys } from "@/features/workspace/api/workspaceApi";
import { useWorkspaceStore } from "@/features/workspace/stores/workspaceStore";
import type { TreeNode } from "@/shared/types/workspace";
import { cn } from "@/shared/utils/cn";

interface FolderContentsListProps {
  folderPath: string;
  className?: string;
}

export function FolderContentsList({ folderPath, className }: FolderContentsListProps) {
  const openFile = useWorkspaceStore((s) => s.openFile);
  const openFolder = useWorkspaceStore((s) => s.openFolder);
  const activeTab = useWorkspaceStore((s) => s.activeTab);

  const { data, isLoading, isError } = useQuery({
    queryKey: workspaceKeys.tree(folderPath, 1),
    queryFn: () => fetchTree(folderPath, 1),
    staleTime: 30_000,
  });

  const nodes = data?.nodes ?? [];
  const folders = nodes.filter((node) => node.type === "folder");
  const files = nodes.filter((node) => node.type === "file");

  const handleOpen = (node: TreeNode) => {
    if (node.type === "folder") {
      openFolder(node.path);
      return;
    }
    openFile(node.path);
  };

  return (
    <section className={cn("flex min-h-0 flex-col", className)} aria-label="Folder contents">
      <header className="shrink-0 border-b border-border/40 px-3 py-2">
        <h3 className="text-xs font-medium uppercase tracking-wide text-content-subtle">
          Contents
        </h3>
        <p className="mt-0.5 text-[11px] text-content-muted">
          {folders.length} folder{folders.length === 1 ? "" : "s"} · {files.length} file
          {files.length === 1 ? "" : "s"}
        </p>
      </header>

      <div className="min-h-0 flex-1 overflow-y-auto px-2 py-2">
        {isLoading ? (
          <p className="px-2 py-3 text-xs text-content-subtle">Loading contents…</p>
        ) : isError ? (
          <p className="px-2 py-3 text-xs text-red-400">Failed to load folder contents.</p>
        ) : nodes.length === 0 ? (
          <p className="px-2 py-3 text-xs text-content-subtle">This folder is empty.</p>
        ) : (
          <ul className="space-y-0.5" role="list">
            {nodes.map((node) => {
              const isActive =
                activeTab?.path === node.path &&
                activeTab.kind === (node.type === "folder" ? "folder" : "file");

              return (
                <li key={node.path}>
                  <button
                    type="button"
                    onClick={() => handleOpen(node)}
                    className={cn(
                      "flex w-full items-center gap-2 rounded-lg px-2 py-1.5 text-left text-[13px] transition-colors",
                      isActive
                        ? "bg-surface-overlay text-content"
                        : "text-content-muted hover:bg-surface-overlay/60 hover:text-content",
                    )}
                    title={node.path}
                  >
                    <span className="flex h-4 w-4 shrink-0 items-center justify-center text-content-subtle">
                      {node.type === "folder" ? <FolderIcon /> : <FileIcon />}
                    </span>
                    <span className="min-w-0 flex-1 truncate">{node.name}</span>
                    {node.type === "folder" && node.hasChildren ? (
                      <span className="shrink-0 text-[10px] text-content-subtle">›</span>
                    ) : null}
                  </button>
                </li>
              );
            })}
          </ul>
        )}
      </div>
    </section>
  );
}

function FolderIcon() {
  return (
    <svg width="12" height="12" viewBox="0 0 12 12" fill="none" aria-hidden>
      <path
        d="M1.5 3h3.2l1 1.2H10.5V9.5H1.5V3z"
        stroke="currentColor"
        strokeWidth="1.2"
        strokeLinejoin="round"
      />
    </svg>
  );
}

function FileIcon() {
  return (
    <svg width="12" height="12" viewBox="0 0 12 12" fill="none" aria-hidden>
      <path
        d="M3.5 1.5h3l2.5 2.5v6.5h-5.5v-9z"
        stroke="currentColor"
        strokeWidth="1.2"
        strokeLinejoin="round"
      />
    </svg>
  );
}
