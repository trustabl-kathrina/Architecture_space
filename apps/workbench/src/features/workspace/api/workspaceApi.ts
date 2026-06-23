import { env } from "@/shared/config/env";
import {
  apiRequest,
  mapTreeNode,
  mapTreeResponse,
  mapWorkspaceInfo,
} from "@/shared/api/client";
import type {
  CreateDocumentRequest,
  CreateFolderRequest,
  DeleteNodeResponse,
  TreeNode,
  TreeResponse,
  UpdateNodeRequest,
  WorkspaceInfo,
} from "@/shared/types/workspace";

const BASE = env.apiBaseUrl;

export const workspaceKeys = {
  all: ["workspace"] as const,
  info: () => [...workspaceKeys.all, "info"] as const,
  tree: (parentPath: string, depth: number) =>
    [...workspaceKeys.all, "tree", parentPath, depth] as const,
};

export async function fetchWorkspaceInfo(): Promise<WorkspaceInfo> {
  const raw = await apiRequest<Record<string, unknown>>(BASE, "/workspace");
  return mapWorkspaceInfo(raw);
}

export async function fetchTree(parentPath = "", depth = 1): Promise<TreeResponse> {
  const params = new URLSearchParams({
    parent_path: parentPath,
    depth: String(depth),
  });
  const raw = await apiRequest<Record<string, unknown>>(BASE, `/workspace/tree?${params}`);
  return mapTreeResponse(raw);
}

export async function createFolder(request: CreateFolderRequest): Promise<TreeNode> {
  const raw = await apiRequest<Record<string, unknown>>(BASE, "/workspace/folders", {
    method: "POST",
    body: { parent_path: request.parentPath, name: request.name },
  });
  return mapTreeNode(raw);
}

export async function createDocument(request: CreateDocumentRequest): Promise<TreeNode> {
  const raw = await apiRequest<Record<string, unknown>>(BASE, "/workspace/documents", {
    method: "POST",
    body: {
      parent_path: request.parentPath,
      name: request.name,
      template_type: request.templateType ?? "overview",
    },
  });
  return mapTreeNode(raw);
}

export async function updateNode(request: UpdateNodeRequest): Promise<TreeNode> {
  const raw = await apiRequest<Record<string, unknown>>(BASE, "/workspace/nodes", {
    method: "PATCH",
    body: {
      path: request.path,
      new_name: request.newName,
      new_parent_path: request.newParentPath,
    },
  });
  return mapTreeNode(raw);
}

export async function deleteNode(path: string): Promise<DeleteNodeResponse> {
  const params = new URLSearchParams({ path });
  const raw = await apiRequest<Record<string, unknown>>(BASE, `/workspace/nodes?${params}`, {
    method: "DELETE",
  });
  return {
    deleted: String(raw.deleted),
    type: raw.type as DeleteNodeResponse["type"],
  };
}

/** Merge loaded children into an existing tree by parent path. */
export function mergeTreeChildren(
  nodes: TreeNode[],
  parentPath: string,
  children: TreeNode[],
): TreeNode[] {
  if (!parentPath) {
    return children;
  }

  return nodes.map((node) => {
    if (node.path === parentPath) {
      return { ...node, children, hasChildren: children.length > 0 };
    }
    if (node.type === "folder" && node.children && parentPath.startsWith(`${node.path}/`)) {
      return {
        ...node,
        children: mergeTreeChildren(node.children, parentPath, children),
      };
    }
    return node;
  });
}
