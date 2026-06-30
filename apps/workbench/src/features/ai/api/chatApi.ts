import { env } from "@/shared/config/env";
import { apiRequest } from "@/shared/api/client";
import type {
  Conversation,
  ResolveConversationRequest,
  ScopeKind,
  SectionContext,
  SendMessageRequest,
  SendMessageResponse,
} from "@/shared/types/chat";

import { mapConversation, mapSendMessageResponse } from "@/features/ai/api/chatMappers";
import { mapSectionContext } from "@/features/ai/api/sectionContextMappers";

const BASE = env.apiBaseUrl;

export const chatKeys = {
  all: ["chat"] as const,
  conversation: (id: string) => [...chatKeys.all, "conversation", id] as const,
  sectionContext: (scopeKind: string, scopePath: string) =>
    [...chatKeys.all, "section-context", scopeKind, scopePath] as const,
};

export interface CreateConversationOptions {
  documentPath?: string | null;
  folderPath?: string | null;
}

export async function fetchSectionContext(
  scopeKind: ScopeKind,
  scopePath: string,
): Promise<SectionContext> {
  const params = new URLSearchParams({
    scope_kind: scopeKind,
    scope_path: scopePath,
  });
  const raw = await apiRequest<Record<string, unknown>>(
    BASE,
    `/chat/section-context?${params.toString()}`,
  );
  return mapSectionContext(raw);
}

export async function resolveConversation(
  request: ResolveConversationRequest,
): Promise<Conversation> {
  const raw = await apiRequest<Record<string, unknown>>(BASE, "/chat/conversations/resolve", {
    method: "POST",
    body: {
      scope_kind: request.scopeKind,
      scope_path: request.scopePath,
      chat_mode: request.chatMode,
    },
  });
  return mapConversation(raw);
}

export async function createConversation(
  options?: string | null | CreateConversationOptions,
): Promise<Conversation> {
  const payload =
    typeof options === "string" || options === null || options === undefined
      ? { document_path: options ?? null }
      : {
          document_path: options.documentPath ?? null,
          folder_path: options.folderPath ?? null,
        };

  const raw = await apiRequest<Record<string, unknown>>(BASE, "/chat/conversations", {
    method: "POST",
    body: payload,
  });
  return mapConversation(raw);
}

export async function fetchConversation(conversationId: string): Promise<Conversation> {
  const raw = await apiRequest<Record<string, unknown>>(BASE, `/chat/conversations/${conversationId}`);
  return mapConversation(raw);
}

export async function clearConversation(conversationId: string): Promise<Conversation> {
  const raw = await apiRequest<Record<string, unknown>>(
    BASE,
    `/chat/conversations/${conversationId}/clear`,
    { method: "POST" },
  );
  return mapConversation(raw);
}

export async function editMessage(
  conversationId: string,
  messageId: string,
  content: string,
): Promise<Conversation> {
  const raw = await apiRequest<Record<string, unknown>>(
    BASE,
    `/chat/conversations/${conversationId}/messages/${messageId}`,
    {
      method: "PATCH",
      body: { content },
    },
  );
  return mapConversation(raw);
}

export async function deleteMessage(
  conversationId: string,
  messageId: string,
): Promise<Conversation> {
  const raw = await apiRequest<Record<string, unknown>>(
    BASE,
    `/chat/conversations/${conversationId}/messages/${messageId}`,
    { method: "DELETE" },
  );
  return mapConversation(raw);
}

export async function sendChatMessage(
  conversationId: string,
  request: SendMessageRequest,
): Promise<SendMessageResponse> {
  const raw = await apiRequest<Record<string, unknown>>(
    BASE,
    `/chat/conversations/${conversationId}/messages`,
    {
      method: "POST",
      body: {
        content: request.content,
        document_path: request.documentPath ?? null,
        folder_path: request.folderPath ?? null,
        folder_plan: request.folderPlan ?? null,
        folder_contents: request.folderContents ?? [],
        chat_mode: request.chatMode ?? null,
        selection: request.selection ?? null,
        open_paths: request.openPaths ?? [],
        active_section: request.activeSection ?? null,
        document_outline: request.documentOutline ?? [],
      },
    },
  );
  return mapSendMessageResponse(raw);
}
