import type { MouseEvent } from "react";

import { useDraggableNode, useDroppableFolder } from "@/features/workspace/hooks/useTreeDnD";
import { useWorkspaceStore } from "@/features/workspace/stores/workspaceStore";
import type { TreeNode } from "@/shared/types/workspace";
import { cn } from "@/shared/utils/cn";

interface DocTreeNodeProps {
  node: TreeNode;
  depth: number;
  onLoadChildren: (path: string) => Promise<void>;
  onSelectFile: (node: TreeNode) => void;
  onSelectFolder: (node: TreeNode) => void;
  onContextMenu: (node: TreeNode, x: number, y: number) => void;
}

export function DocTreeNode({
  node,
  depth,
  onLoadChildren,
  onSelectFile,
  onSelectFolder,
  onContextMenu,
}: DocTreeNodeProps) {
  const isExpanded = useWorkspaceStore((s) => s.isExpanded(node.path));
  const toggleExpanded = useWorkspaceStore((s) => s.toggleExpanded);
  const expandPath = useWorkspaceStore((s) => s.expandPath);
  const isTabActive = useWorkspaceStore((s) => s.isTabActive);
  const isSelected = isTabActive({
    kind: node.type === "folder" ? "folder" : "file",
    path: node.path,
  });

  const { attributes, listeners, setNodeRef, style, isDragging } = useDraggableNode(node);
  const { isOver, setNodeRef: setDropRef } = useDroppableFolder(node);

  const ensureExpanded = async () => {
    if (isExpanded) {
      return;
    }
    if (node.hasChildren) {
      await onLoadChildren(node.path);
      return;
    }
    expandPath(node.path);
  };

  const handleChevronClick = async (event: MouseEvent) => {
    event.stopPropagation();
    if (node.type !== "folder") {
      return;
    }
    if (isExpanded) {
      toggleExpanded(node.path);
      return;
    }
    if (node.hasChildren) {
      await onLoadChildren(node.path);
      return;
    }
    toggleExpanded(node.path);
  };

  const handleRowClick = async () => {
    if (node.type === "folder") {
      await ensureExpanded();
      onSelectFolder(node);
      return;
    }
    onSelectFile(node);
  };

  const setRefs = (element: HTMLDivElement | null) => {
    setNodeRef(element);
    if (node.type === "folder") {
      setDropRef(element);
    }
  };

  return (
    <div>
      <div
        ref={setRefs}
        style={style}
        {...attributes}
        {...listeners}
        role="treeitem"
        aria-expanded={node.type === "folder" ? isExpanded : undefined}
        aria-selected={isSelected}
        className={cn(
          "group mx-1.5 flex cursor-pointer items-center gap-1.5 rounded-lg px-2 py-1.5 text-[13px] transition-colors",
          isSelected
            ? "bg-surface-overlay text-content"
            : "text-content-muted hover:bg-surface-overlay/60 hover:text-content",
          isDragging && "opacity-40",
          isOver && node.type === "folder" && "ring-1 ring-accent/40",
        )}
        onClick={() => void handleRowClick()}
        onContextMenu={(event) => {
          event.preventDefault();
          onContextMenu(node, event.clientX, event.clientY);
        }}
      >
        <span style={{ width: depth * 14 }} className="shrink-0" />
        {node.type === "folder" ? (
          <button
            type="button"
            className="flex h-4 w-4 shrink-0 items-center justify-center rounded text-content-subtle hover:bg-surface-overlay hover:text-content"
            aria-label={isExpanded ? "Collapse folder" : "Expand folder"}
            onClick={(event) => void handleChevronClick(event)}
          >
            <ChevronIcon open={isExpanded && node.hasChildren} />
          </button>
        ) : (
          <span className="flex h-4 w-4 shrink-0 items-center justify-center text-content-subtle">
            <FileIcon />
          </span>
        )}
        <span className={cn("min-w-0 flex-1 truncate", node.type === "file" && "font-normal")}>
          {node.name}
        </span>
      </div>

      {node.type === "folder" && isExpanded && node.children && node.children.length > 0 ? (
        <div role="group">
          {node.children.map((child) => (
            <DocTreeNode
              key={child.path}
              node={child}
              depth={depth + 1}
              onLoadChildren={onLoadChildren}
              onSelectFile={onSelectFile}
              onSelectFolder={onSelectFolder}
              onContextMenu={onContextMenu}
            />
          ))}
        </div>
      ) : null}
    </div>
  );
}

function ChevronIcon({ open }: { open: boolean }) {
  return (
    <svg width="12" height="12" viewBox="0 0 12 12" fill="none" aria-hidden>
      <path
        d={open ? "M3 4.5L6 7.5L9 4.5" : "M4.5 3L7.5 6L4.5 9"}
        stroke="currentColor"
        strokeWidth="1.5"
        strokeLinecap="round"
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
