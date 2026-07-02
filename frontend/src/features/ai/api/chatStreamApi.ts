import { mapExecutionStep, mapSendMessageResponse } from "@/features/ai/api/chatMappers";
import {
  normalizeRegenerateMessageRequest,
  normalizeSendMessageRequest,
} from "@/features/ai/lib/normalizeChatRequest";
import { env } from "@/shared/config/env";
import { ApiError } from "@/shared/api/client";
import type { ChatStreamEvent, RegenerateMessageRequest, SendMessageRequest } from "@/shared/types/chat";

function mapStreamEvent(raw: Record<string, unknown>): ChatStreamEvent {
  const type = raw.type as ChatStreamEvent["type"];
  return {
    type,
    message: raw.message != null ? String(raw.message) : null,
    agent: raw.agent != null ? (raw.agent as ChatStreamEvent["agent"]) : null,
    step: raw.step ? mapExecutionStep(raw.step as Record<string, unknown>) : null,
    steps: Array.isArray(raw.steps)
      ? raw.steps.map((step) => mapExecutionStep(step as Record<string, unknown>))
      : null,
    content: raw.content != null ? String(raw.content) : null,
    response: raw.response
      ? mapSendMessageResponse(raw.response as Record<string, unknown>)
      : null,
  };
}

function buildMessagePayload(
  request: SendMessageRequest | RegenerateMessageRequest,
): Record<string, unknown> {
  const normalized =
    "content" in request
      ? normalizeSendMessageRequest(request)
      : normalizeRegenerateMessageRequest(request);

  return {
    document_path: normalized.documentPath ?? null,
    folder_path: normalized.folderPath ?? null,
    folder_plan: normalized.folderPlan ?? null,
    folder_contents: normalized.folderContents ?? [],
    chat_mode: normalized.chatMode ?? null,
    selection: "selection" in normalized ? (normalized.selection ?? null) : null,
    open_paths: normalized.openPaths ?? [],
    active_section: normalized.activeSection ?? null,
    document_outline: normalized.documentOutline ?? [],
  };
}

async function consumeSseStream(
  response: Response,
  onEvent: (event: ChatStreamEvent) => void,
): Promise<void> {
  if (!response.ok) {
    const text = await response.text();
    try {
      const body = JSON.parse(text) as {
        code: string;
        message: string;
        details?: Record<string, unknown>;
      };
      throw new ApiError(response.status, body);
    } catch (error) {
      if (error instanceof ApiError) {
        throw error;
      }
      throw new Error(text || response.statusText || `HTTP ${response.status}`);
    }
  }

  const reader = response.body?.getReader();
  if (!reader) {
    throw new Error("Streaming is not supported in this browser");
  }

  const decoder = new TextDecoder();
  let buffer = "";
  let completed = false;

  while (true) {
    const { done, value } = await reader.read();
    if (done) {
      break;
    }
    buffer += decoder.decode(value, { stream: true });
    const parts = buffer.split("\n\n");
    buffer = parts.pop() ?? "";

    for (const part of parts) {
      const line = part.trim();
      if (!line.startsWith("data:")) {
        continue;
      }
      const payload = line.slice(5).trim();
      if (!payload) {
        continue;
      }

      let raw: Record<string, unknown>;
      try {
        raw = JSON.parse(payload) as Record<string, unknown>;
      } catch {
        if (!completed) {
          throw new Error("Received malformed stream data from the server");
        }
        continue;
      }

      const event = mapStreamEvent(raw);
      if (event.type === "done") {
        completed = true;
      }
      if (event.type === "error" && completed) {
        continue;
      }

      onEvent(event);

      if (event.type === "error") {
        return;
      }
    }
  }

  if (!completed) {
    throw new Error("The assistant stopped responding before finishing. Please try again.");
  }
}

export async function streamChatMessage(
  conversationId: string,
  request: SendMessageRequest,
  onEvent: (event: ChatStreamEvent) => void,
): Promise<void> {
  const normalized = normalizeSendMessageRequest(request);
  const response = await fetch(
    `${env.apiBaseUrl}/chat/conversations/${conversationId}/messages/stream`,
    {
      method: "POST",
      headers: { "Content-Type": "application/json", Accept: "text/event-stream" },
      body: JSON.stringify({
        content: normalized.content,
        ...buildMessagePayload(normalized),
      }),
    },
  );

  await consumeSseStream(response, onEvent);
}

export async function streamRegenerateMessage(
  conversationId: string,
  messageId: string,
  request: RegenerateMessageRequest,
  onEvent: (event: ChatStreamEvent) => void,
): Promise<void> {
  const normalized = normalizeRegenerateMessageRequest(request);
  const response = await fetch(
    `${env.apiBaseUrl}/chat/conversations/${conversationId}/messages/${messageId}/regenerate/stream`,
    {
      method: "POST",
      headers: { "Content-Type": "application/json", Accept: "text/event-stream" },
      body: JSON.stringify(buildMessagePayload(normalized)),
    },
  );

  await consumeSseStream(response, onEvent);
}

