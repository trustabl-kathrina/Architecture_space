export type NodeType = "folder" | "file";

export type TabKind = "file" | "folder";

export interface WorkbenchTab {
  kind: TabKind;
  path: string;
}

export function tabKey(tab: WorkbenchTab): string {
  return `${tab.kind}:${tab.path}`;
}

export function tabsEqual(a: WorkbenchTab | null, b: WorkbenchTab | null): boolean {
  if (!a || !b) {
    return a === b;
  }
  return a.kind === b.kind && a.path === b.path;
}

export interface TreeNode {
  id: string;
  name: string;
  path: string;
  type: NodeType;
  hasChildren: boolean;
  children?: TreeNode[] | null;
}

export interface TreeResponse {
  parentPath: string;
  nodes: TreeNode[];
}

export interface WorkspaceInfo {
  root: string;
  name: string;
  docsRoot: string;
}

export interface CreateFolderRequest {
  parentPath: string;
  name: string;
}

export interface CreateDocumentRequest {
  parentPath: string;
  name: string;
  templateType?: string;
}

export interface UpdateNodeRequest {
  path: string;
  newName?: string;
  newParentPath?: string;
}

export interface DeleteNodeResponse {
  deleted: string;
  type: NodeType;
}

export interface ApiErrorBody {
  code: string;
  message: string;
  details?: Record<string, unknown>;
}
