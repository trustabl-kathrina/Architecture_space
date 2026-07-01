import { useMutation, useQuery, useQueryClient } from "@tanstack/react-query";
import { useCallback } from "react";

import {
  createDocument,
  createFolder,
  deleteNode,
  fetchTree,
  fetchWorkspaceInfo,
  mergeTreeChildren,
  updateNode,
  workspaceKeys,
} from "@/features/workspace/api/workspaceApi";
import { normalizeWorkspacePath, normalizeWorkspacePaths } from "@/features/workspace/lib/pathMigration";
import { useWorkspaceStore } from "@/features/workspace/stores/workspaceStore";
import { ApiError } from "@/shared/api/client";
import type { TreeNode, TreeResponse } from "@/shared/types/workspace";

async function fetchTreeWithExpandedBranches(): Promise<TreeResponse> {
  const root = await fetchTree("", 1);
  let nodes = root.nodes;
  const expanded = normalizeWorkspacePaths(
    useWorkspaceStore.getState().expandedPaths.map(normalizeWorkspacePath),
  );
  const sorted = [...expanded].sort(
    (a, b) => a.split("/").length - b.split("/").length,
  );

  const staleExpanded: string[] = [];

  for (const parentPath of sorted) {
    try {
      const children = await fetchTree(parentPath, 1);
      nodes = mergeTreeChildren(nodes, parentPath, children.nodes);
    } catch (error) {
      if (error instanceof ApiError && error.status === 404) {
        staleExpanded.push(parentPath);
        continue;
      }
      throw error;
    }
  }

  if (staleExpanded.length > 0) {
    const collapsePath = useWorkspaceStore.getState().collapsePath;
    for (const path of staleExpanded) {
      collapsePath(path);
    }
  }

  return { parentPath: "", nodes };
}

export function useWorkspaceInfo() {
  return useQuery({
    queryKey: workspaceKeys.info(),
    queryFn: fetchWorkspaceInfo,
    staleTime: 0,
    refetchOnWindowFocus: true,
  });
}

export function useDocTree() {
  const queryClient = useQueryClient();
  const expandPath = useWorkspaceStore((s) => s.expandPath);
  const treeFilter = useWorkspaceStore((s) => s.treeFilter);
  const pathsReconciled = useWorkspaceStore((s) => s.pathsReconciled);

  const rootQuery = useQuery({
    queryKey: workspaceKeys.tree("", 1),
    queryFn: fetchTreeWithExpandedBranches,
    enabled: pathsReconciled,
    staleTime: 0,
    refetchOnMount: "always",
    refetchOnWindowFocus: true,
  });

  const refreshTree = useCallback(async () => {
    const fresh = await fetchTreeWithExpandedBranches();
    queryClient.setQueryData(workspaceKeys.tree("", 1), fresh);
    return fresh;
  }, [queryClient]);

  const loadChildren = async (parentPath: string) => {
    const response = await fetchTree(parentPath, 1);
    queryClient.setQueryData<TreeResponse>(workspaceKeys.tree("", 1), (current) => {
      const base = current ?? rootQuery.data;
      if (!base) {
        return { parentPath: "", nodes: response.nodes };
      }
      return {
        ...base,
        nodes: mergeTreeChildren(base.nodes, parentPath, response.nodes),
      };
    });
    expandPath(parentPath);
    await refreshTree();
  };

  const invalidateTree = () => {
    void queryClient.invalidateQueries({ queryKey: workspaceKeys.all });
  };

  const createFolderMutation = useMutation({
    mutationFn: createFolder,
    onSuccess: invalidateTree,
  });

  const createDocumentMutation = useMutation({
    mutationFn: createDocument,
    onSuccess: invalidateTree,
  });

  const updateNodeMutation = useMutation({
    mutationFn: updateNode,
    onSuccess: invalidateTree,
  });

  const deleteNodeMutation = useMutation({
    mutationFn: deleteNode,
    onSuccess: invalidateTree,
  });

  const nodes = rootQuery.data?.nodes ?? [];
  const filteredNodes = treeFilter.trim()
    ? filterTree(nodes, treeFilter.trim().toLowerCase())
    : nodes;

  return {
    nodes,
    filteredNodes,
    isLoading: rootQuery.isLoading,
    isFetching: rootQuery.isFetching,
    isError: rootQuery.isError,
    error: rootQuery.error,
    refetch: rootQuery.refetch,
    refreshTree,
    loadChildren,
    createFolder: createFolderMutation.mutateAsync,
    createDocument: createDocumentMutation.mutateAsync,
    updateNode: updateNodeMutation.mutateAsync,
    deleteNode: deleteNodeMutation.mutateAsync,
    isMutating:
      createFolderMutation.isPending ||
      createDocumentMutation.isPending ||
      updateNodeMutation.isPending ||
      deleteNodeMutation.isPending,
  };
}

function filterTree(nodes: TreeNode[], query: string): TreeNode[] {
  const result: TreeNode[] = [];
  for (const node of nodes) {
    const nameMatch = node.name.toLowerCase().includes(query);
    const childMatches = node.children ? filterTree(node.children, query) : [];
    if (nameMatch || childMatches.length > 0) {
      result.push({
        ...node,
        children: childMatches.length > 0 ? childMatches : node.children,
      });
    }
  }
  return result;
}

/** Invalidate workspace tree queries (call after disk writes). */
export function invalidateWorkspaceTree(queryClient: { invalidateQueries: (opts: { queryKey: readonly string[] }) => void }) {
  queryClient.invalidateQueries({ queryKey: workspaceKeys.all });
}
