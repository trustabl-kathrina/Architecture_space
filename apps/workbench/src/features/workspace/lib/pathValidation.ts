import { fetchDocument } from "@/features/editor/api/documentsApi";
import { fetchTree } from "@/features/workspace/api/workspaceApi";
import { ApiError } from "@/shared/api/client";

export async function workspacePathExists(path: string): Promise<boolean> {
  const trimmed = path.trim();
  if (!trimmed) {
    return false;
  }

    if (trimmed.toLowerCase().endsWith(".md")) {
    try {
      await fetchDocument(trimmed);
      return true;
    } catch (error) {
      if (error instanceof ApiError && error.status === 404) {
        return false;
      }
      return true;
    }
  }

  const slash = trimmed.lastIndexOf("/");
  const parentPath = slash === -1 ? "" : trimmed.slice(0, slash);
  const folderName = slash === -1 ? trimmed : trimmed.slice(slash + 1);

  try {
    const tree = await fetchTree(parentPath, 1);
    return tree.nodes.some((node) => node.path === trimmed || node.name === folderName);
  } catch (error) {
    if (error instanceof ApiError && error.status === 404) {
      return false;
    }
    return true;
  }
}
