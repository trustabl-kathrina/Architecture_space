import { useEffect, useRef } from "react";

import type { TreeNode } from "@/shared/types/workspace";

interface TreeContextMenuProps {
  node: TreeNode;
  position: { x: number; y: number };
  onClose: () => void;
  onCreateFolder: () => void;
  onCreateDocument: () => void;
  onRename: () => void;
  onDelete: () => void;
}

export function TreeContextMenu({
  node,
  position,
  onClose,
  onCreateFolder,
  onCreateDocument,
  onRename,
  onDelete,
}: TreeContextMenuProps) {
  const ref = useRef<HTMLDivElement>(null);

  useEffect(() => {
    const handleClick = (event: MouseEvent) => {
      if (ref.current && !ref.current.contains(event.target as Node)) {
        onClose();
      }
    };
    const handleKey = (event: KeyboardEvent) => {
      if (event.key === "Escape") {
        onClose();
      }
    };
    document.addEventListener("mousedown", handleClick);
    document.addEventListener("keydown", handleKey);
    return () => {
      document.removeEventListener("mousedown", handleClick);
      document.removeEventListener("keydown", handleKey);
    };
  }, [onClose]);

  const folderParent = node.type === "folder" ? node.path : parentPath(node.path);

  return (
    <div
      ref={ref}
      className="fixed z-50 min-w-44 rounded-lg border border-border bg-surface-raised py-1 shadow-xl"
      style={{ left: position.x, top: position.y }}
      role="menu"
    >
      <MenuItem
        label="New folder"
        onClick={() => {
          onCreateFolder();
          onClose();
        }}
      />
      <MenuItem
        label="New document"
        onClick={() => {
          onCreateDocument();
          onClose();
        }}
      />
      <div className="my-1 border-t border-border" />
      <MenuItem
        label="Rename"
        onClick={() => {
          onRename();
          onClose();
        }}
      />
      <MenuItem
        label="Delete"
        danger
        onClick={() => {
          onDelete();
          onClose();
        }}
      />
      <p className="px-3 py-1 text-[10px] text-content-subtle truncate" title={folderParent || "docs/"}>
        in /{folderParent || "docs"}
      </p>
    </div>
  );
}

function MenuItem({
  label,
  onClick,
  danger = false,
}: {
  label: string;
  onClick: () => void;
  danger?: boolean;
}) {
  return (
    <button
      type="button"
      role="menuitem"
      className={`block w-full px-3 py-1.5 text-left text-sm hover:bg-surface-overlay ${
        danger ? "text-red-400" : "text-content"
      }`}
      onClick={onClick}
    >
      {label}
    </button>
  );
}

function parentPath(path: string): string {
  const index = path.lastIndexOf("/");
  return index === -1 ? "" : path.slice(0, index);
}
