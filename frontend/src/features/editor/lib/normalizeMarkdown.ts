const JSON_FENCE = /```json\s*([\s\S]*?)\s*```/i;
const MARKDOWN_FENCE = /^```(?:markdown|md)?\s*\n([\s\S]*?)\n```\s*$/i;

const MARKDOWN_KEYS = [
  "response",
  "answer",
  "content",
  "message",
  "text",
  "reply",
  "proposed_body",
  "proposedBody",
  "body",
  "markdown",
] as const;

/** Normalize assistant/model text for markdown rendering. */
export function normalizeMarkdownText(text: string): string {
  let cleaned = text.trim();
  if (!cleaned) {
    return "";
  }

  cleaned = unwrapModelPayload(cleaned);
  cleaned = stripCodeFences(cleaned);
  cleaned = cleaned.replace(/<br\s*\/?>/gi, "\n");

  return cleaned.trim();
}

function unwrapModelPayload(text: string): string {
  const fence = text.match(JSON_FENCE);
  if (fence?.[1]) {
    const fromJson = extractMarkdownFromJson(fence[1].trim());
    if (fromJson) {
      return fromJson;
    }
    if (!fence[1].trim().startsWith("{")) {
      return fence[1].trim();
    }
  }

  if (text.startsWith("{")) {
    const fromJson = extractMarkdownFromJson(text);
    if (fromJson) {
      return fromJson;
    }
  }

  return text;
}

function extractMarkdownFromJson(text: string): string | null {
  try {
    const data = JSON.parse(text) as unknown;
    if (typeof data === "string" && data.trim()) {
      return data.trim();
    }
    if (data && typeof data === "object") {
      for (const key of MARKDOWN_KEYS) {
        const value = (data as Record<string, unknown>)[key];
        if (typeof value === "string" && value.trim()) {
          return value.trim();
        }
      }
    }
  } catch {
    const start = text.indexOf("{");
    const end = text.lastIndexOf("}");
    if (start !== -1 && end > start) {
      try {
        return extractMarkdownFromJson(text.slice(start, end + 1));
      } catch {
        return null;
      }
    }
  }
  return null;
}

function stripCodeFences(text: string): string {
  const markdownMatch = text.match(MARKDOWN_FENCE);
  if (markdownMatch?.[1]) {
    return markdownMatch[1].trim();
  }

  if (text.startsWith("```")) {
    const lines = text.split("\n");
    if (lines[0]?.startsWith("```")) {
      lines.shift();
    }
    if (lines.length > 0 && lines[lines.length - 1]?.trim() === "```") {
      lines.pop();
    }
    return lines.join("\n").trim();
  }

  return text;
}
