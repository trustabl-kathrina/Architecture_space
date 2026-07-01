import type { ApiErrorBody } from "@/shared/types/workspace";

export class ApiError extends Error {
  readonly code: string;
  readonly status: number;
  readonly details: Record<string, unknown>;

  constructor(status: number, body: ApiErrorBody) {
    super(body.message);
    this.name = "ApiError";
    this.code = body.code;
    this.status = status;
    this.details = body.details ?? {};
  }
}

type RequestOptions = Omit<RequestInit, "body"> & {
  body?: unknown;
};

async function parseError(response: Response): Promise<ApiError> {
  try {
    const body = (await response.json()) as ApiErrorBody;
    return new ApiError(response.status, body);
  } catch {
    return new ApiError(response.status, {
      code: "http_error",
      message: response.statusText || `HTTP ${response.status}`,
    });
  }
}

export async function apiRequest<T>(baseUrl: string, path: string, options: RequestOptions = {}): Promise<T> {
  const { body, headers, ...rest } = options;
  const response = await fetch(`${baseUrl}${path}`, {
    ...rest,
    headers: {
      "Content-Type": "application/json",
      ...headers,
    },
    body: body !== undefined ? JSON.stringify(body) : undefined,
  });

  if (!response.ok) {
    throw await parseError(response);
  }

  if (response.status === 204) {
    return undefined as T;
  }

  return (await response.json()) as T;
}

/** Convert API snake_case keys to camelCase for tree payloads. */
export function mapTreeNode(raw: Record<string, unknown>): import("@/shared/types/workspace").TreeNode {
  return {
    id: String(raw.id),
    name: String(raw.name),
    path: String(raw.path),
    type: raw.type as "folder" | "file",
    hasChildren: Boolean(raw.has_children),
    children: Array.isArray(raw.children)
      ? raw.children.map((child) => mapTreeNode(child as Record<string, unknown>))
      : raw.children === null
        ? null
        : undefined,
  };
}

export function mapTreeResponse(raw: Record<string, unknown>): import("@/shared/types/workspace").TreeResponse {
  const nodes = Array.isArray(raw.nodes)
    ? raw.nodes.map((node) => mapTreeNode(node as Record<string, unknown>))
    : [];
  return {
    parentPath: String(raw.parent_path ?? ""),
    nodes,
  };
}

export function mapWorkspaceInfo(raw: Record<string, unknown>): import("@/shared/types/workspace").WorkspaceInfo {
  return {
    root: String(raw.root),
    name: String(raw.name),
    docsRoot: String(raw.docs_root),
  };
}
