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

  return message;
}
