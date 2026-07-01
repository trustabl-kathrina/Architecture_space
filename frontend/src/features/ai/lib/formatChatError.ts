export function formatChatError(error: unknown): string {
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
