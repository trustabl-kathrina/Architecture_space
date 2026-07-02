import type { RegenerateMessageRequest, SendMessageRequest } from "@/shared/types/chat";

/** Keep in sync with backend SendMessageRequest / RegenerateMessageRequest limits. */
export const CHAT_REQUEST_LIMITS = {
  content: 8000,
  folderPlan: 128000,
  selection: 4000,
  activeSection: 500,
  documentOutlineItems: 80,
  documentOutlineItem: 500,
  folderContentsItems: 120,
  openPaths: 40,
} as const;

function truncate(value: string | null | undefined, max: number): string | null {
  if (value == null) {
    return null;
  }
  const trimmed = value.trim();
  if (!trimmed) {
    return null;
  }
  return trimmed.length > max ? trimmed.slice(0, max) : trimmed;
}

function truncateList(values: string[] | undefined, maxItems: number, maxItem: number): string[] {
  if (!values?.length) {
    return [];
  }
  return values.slice(0, maxItems).map((value) => {
    const text = String(value).trim();
    return text.length > maxItem ? text.slice(0, maxItem) : text;
  });
}

export function normalizeSendMessageRequest(request: SendMessageRequest): SendMessageRequest {
  return {
    ...request,
    content: truncate(request.content, CHAT_REQUEST_LIMITS.content) ?? request.content.slice(0, CHAT_REQUEST_LIMITS.content),
    folderPlan: truncate(request.folderPlan, CHAT_REQUEST_LIMITS.folderPlan),
    selection: truncate(request.selection, CHAT_REQUEST_LIMITS.selection),
    activeSection: truncate(request.activeSection, CHAT_REQUEST_LIMITS.activeSection),
    documentOutline: truncateList(
      request.documentOutline,
      CHAT_REQUEST_LIMITS.documentOutlineItems,
      CHAT_REQUEST_LIMITS.documentOutlineItem,
    ),
    folderContents: truncateList(
      request.folderContents,
      CHAT_REQUEST_LIMITS.folderContentsItems,
      CHAT_REQUEST_LIMITS.documentOutlineItem,
    ),
    openPaths: truncateList(request.openPaths, CHAT_REQUEST_LIMITS.openPaths, 500),
  };
}

export function normalizeRegenerateMessageRequest(
  request: RegenerateMessageRequest,
): RegenerateMessageRequest {
  return {
    ...request,
    folderPlan: truncate(request.folderPlan, CHAT_REQUEST_LIMITS.folderPlan),
    selection: truncate(request.selection, CHAT_REQUEST_LIMITS.selection),
    activeSection: truncate(request.activeSection, CHAT_REQUEST_LIMITS.activeSection),
    documentOutline: truncateList(
      request.documentOutline,
      CHAT_REQUEST_LIMITS.documentOutlineItems,
      CHAT_REQUEST_LIMITS.documentOutlineItem,
    ),
    folderContents: truncateList(
      request.folderContents,
      CHAT_REQUEST_LIMITS.folderContentsItems,
      CHAT_REQUEST_LIMITS.documentOutlineItem,
    ),
    openPaths: truncateList(request.openPaths, CHAT_REQUEST_LIMITS.openPaths, 500),
  };
}
