import { useState } from "react";

import { DocTreeNode } from "@/features/workspace/components/DocTreeNode";
import { TreeContextMenu } from "@/features/workspace/components/TreeContextMenu";
import { TreeSearch } from "@/features/workspace/components/TreeSearch";
import { useDocTree } from "@/features/workspace/hooks/useDocTree";
import { TreeDndProvider } from "@/features/workspace/hooks/useTreeDnD";
import { useWorkspaceStore } from "@/features/workspace/stores/workspaceStore";
import type { TreeNode } from "@/shared/types/workspace";

export function DocTree() {
  const {
    filteredNodes,
    isLoading,
    isError,
    error,
    loadChildren,
    refreshTree,
    createFolder,
    createDocument,
    updateNode,
    deleteNode,
    isMutating,
    isFetching,
  } = useDocTree();

  const pathsReconciled = useWorkspaceStore((s) => s.pathsReconciled);
  const setSelectedPath = useWorkspaceStore((s) => s.openFile);
  const [menu, setMenu] = useState<{ node: TreeNode; x: number; y: number } | null>(null);

  const handleMove = async (path: string, newParentPath: string) => {
    await updateNode({ path, newParentPath });
  };

  const handleCreateFolder = async (parentPath: string) => {
    const name = window.prompt("Folder name:");
    if (!name?.trim()) {
      return;
    }
    await createFolder({ parentPath, name: name.trim() });
  };

  const handleCreateDocument = async (parentPath: string) => {
    const name = window.prompt("Document name (without .md):");
    if (!name?.trim()) {
      return;
    }
    await createDocument({ parentPath, name: name.trim() });
  };

  const handleRename = async (node: TreeNode) => {
    const nextName = window.prompt("Rename to:", node.name.replace(/\.md$/i, ""));
    if (!nextName?.trim()) {
      return;
    }
    await updateNode({ path: node.path, newName: nextName.trim() });
  };

  const handleDelete = async (node: TreeNode) => {
    const confirmed = window.confirm(`Delete ${node.name}?`);
    if (!confirmed) {
      return;
    }
    await deleteNode(node.path);
  };

  if (!pathsReconciled || isLoading) {
    return <p className="px-3 py-2 text-sm text-content-muted">Loading documentation tree…</p>;
  }

  if (isError) {
    return (
      <p className="px-3 py-2 text-sm text-red-400">
        {error instanceof Error ? error.message : "Failed to load tree"}
      </p>
    );
  }

  return (
    <TreeDndProvider onMove={handleMove}>
      <div className="flex h-full flex-col">
        <TreeSearch />
        <div className="flex-1 overflow-y-auto px-1 py-2" role="tree" aria-label="Documentation tree">
          {filteredNodes.length === 0 ? (
            <p className="px-2 text-sm text-content-muted">No documents found.</p>
          ) : (
            filteredNodes.map((node) => (
              <DocTreeNode
                key={node.path}
                node={node}
                depth={0}
                onLoadChildren={loadChildren}
                onSelect={(selected) => {
                  if (selected.type === "file") {
                    void refreshTree();
                    setSelectedPath(selected.path);
                  }
                }}
                onContextMenu={(node, x, y) => setMenu({ node, x, y })}
              />
            ))
          )}
        </div>
        {isMutating || isFetching ? (
          <p className="border-t border-border px-3 py-1 text-xs text-content-subtle">
            {isMutating ? "Saving…" : "Syncing with disk…"}
          </p>
        ) : null}
        {menu ? (
          <TreeContextMenu
            node={menu.node}
            position={{ x: menu.x, y: menu.y }}
            onClose={() => setMenu(null)}
            onCreateFolder={() =>
              handleCreateFolder(
                menu.node.type === "folder" ? menu.node.path : parentPathOf(menu.node),
              )
            }
            onCreateDocument={() =>
              handleCreateDocument(menu.node.type === "folder" ? menu.node.path : parentPathOf(menu.node))
            }
            onRename={() => handleRename(menu.node)}
            onDelete={() => handleDelete(menu.node)}
          />
        ) : null}
      </div>
    </TreeDndProvider>
  );
}

function parentPathOf(node: TreeNode): string {
  const index = node.path.lastIndexOf("/");
  return index === -1 ? "" : node.path.slice(0, index);
}
