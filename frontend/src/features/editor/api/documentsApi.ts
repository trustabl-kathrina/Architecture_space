import { env } from "@/shared/config/env";
import { apiRequest } from "@/shared/api/client";
import type {
  DocumentContent,
  DocumentMeta,
  UpdateDocumentRequest,
  UpdateDocumentResponse,
} from "@/shared/types/document";

const BASE = env.apiBaseUrl;

export const documentKeys = {
  all: ["documents"] as const,
  detail: (path: string) => [...documentKeys.all, path] as const,
};

function mapMeta(raw: Record<string, unknown>): DocumentMeta {
  return {
    path: String(raw.path),
    title: String(raw.title),
    checksum: String(raw.checksum),
    lastModified: String(raw.last_modified),
    sizeBytes: Number(raw.size_bytes),
  };
}

export async function fetchDocument(path: string): Promise<DocumentContent> {
  const params = new URLSearchParams({ path });
  const raw = await apiRequest<Record<string, unknown>>(BASE, `/documents?${params}`);
  return {
    path: String(raw.path),
    content: String(raw.content),
    checksum: String(raw.checksum),
    meta: mapMeta(raw.meta as Record<string, unknown>),
  };
}

export async function saveDocument(request: UpdateDocumentRequest): Promise<UpdateDocumentResponse> {
  const raw = await apiRequest<Record<string, unknown>>(BASE, "/documents", {
    method: "PUT",
    body: {
      path: request.path,
      content: request.content,
      checksum: request.checksum ?? null,
    },
  });
  return {
    path: String(raw.path),
    checksum: String(raw.checksum),
    meta: mapMeta(raw.meta as Record<string, unknown>),
  };
}
