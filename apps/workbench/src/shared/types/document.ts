export type EditorViewMode = "edit" | "preview" | "split";

export interface DocumentMeta {
  path: string;
  title: string;
  checksum: string;
  lastModified: string;
  sizeBytes: number;
}

export interface DocumentContent {
  path: string;
  content: string;
  checksum: string;
  meta: DocumentMeta;
}

export interface UpdateDocumentRequest {
  path: string;
  content: string;
  checksum?: string | null;
}

export interface UpdateDocumentResponse {
  path: string;
  checksum: string;
  meta: DocumentMeta;
}
