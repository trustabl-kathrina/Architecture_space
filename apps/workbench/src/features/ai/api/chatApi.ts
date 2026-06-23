import { env } from "@/shared/config/env";
import { apiRequest } from "@/shared/api/client";
import type { Conversation, SendMessageRequest, SendMessageResponse } from "@/shared/types/chat";

import { mapConversation, mapSendMessageResponse } from "@/features/ai/api/chatMappers";

const BASE = env.apiBaseUrl;

export const chatKeys = {
  all: ["chat"] as const,
  conversation: (id: string) => [...chatKeys.all, "conversation", id] as const,
};

export async function createConversation(documentPath?: string | null): Promise<Conversation> {
  const raw = await apiRequest<Record<string, unknown>>(BASE, "/chat/conversations", {
    method: "POST",
    body: { document_path: documentPath ?? null },
  });
  return mapConversation(raw);
}

export async function fetchConversation(conversationId: string): Promise<Conversation> {
  const raw = await apiRequest<Record<string, unknown>>(BASE, `/chat/conversations/${conversationId}`);
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
        selection: request.selection ?? null,
        open_paths: request.openPaths ?? [],
        active_section: request.activeSection ?? null,
        document_outline: request.documentOutline ?? [],
      },
    },
  );
  return mapSendMessageResponse(raw);
}
