import { ApiError } from "@/shared/api/client";

function formatValidationError(error: ApiError): string | null {
  if (error.code !== "validation_error") {
    return null;
  }
  const rawErrors = error.details.errors;
  if (!Array.isArray(rawErrors) || rawErrors.length === 0) {
    return error.message;
  }
  const parts = rawErrors.map((entry) => {
    const record = entry as { loc?: unknown[]; msg?: string };
    const field = (record.loc ?? [])
      .filter((part) => part !== "body")
      .map(String)
      .join(".");
    const label = field || "request";
    return `${label}: ${record.msg ?? "invalid value"}`;
  });
  return `Request validation failed — ${parts.join("; ")}`;
}

export function formatChatError(error: unknown): string {
  if (error instanceof ApiError) {
    const validation = formatValidationError(error);
    if (validation) {
      return validation;
    }
  }

  if (!(error instanceof Error)) {
    return "Something went wrong. Please try again.";
  }

  const message = error.message;
  if (message.includes("Invalid structured AI output")) {
    return (
      "The assistant could not format its response. Try rephrasing your question, " +
      "or ask for an explanation in text instead of a diagram."
    );
  }

  if (message.includes("Failed to fetch") || message.includes("NetworkError")) {
    return "Could not reach the API. Check that the backend is running.";
  }

  if (message.includes("internal error") || message.includes("Cursor AI is temporarily unavailable")) {
    return (
      "The AI service is temporarily unavailable. Check CURSOR_API_KEY in .env, " +
      "retry in a moment, or add GEMINI_API_KEY for fallback. " +
      "Manual edits still work — use Save to disk in the editor."
    );
  }

  if (message.includes("Document changed since last load")) {
    return "The file changed on disk since you opened it. Reload from disk, then save again.";
  }

  return message;
}
