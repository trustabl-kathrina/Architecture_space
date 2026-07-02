import { describe, expect, it } from "vitest";

import {
  CHAT_REQUEST_LIMITS,
  normalizeSendMessageRequest,
} from "@/features/ai/lib/normalizeChatRequest";

describe("normalizeSendMessageRequest", () => {
  it("truncates oversized folder plans", () => {
    const longPlan = "x".repeat(CHAT_REQUEST_LIMITS.folderPlan + 500);
    const normalized = normalizeSendMessageRequest({
      content: "implement the plan",
      folderPlan: longPlan,
      folderPath: "section",
      chatMode: "agent",
    });
    expect(normalized.folderPlan?.length).toBe(CHAT_REQUEST_LIMITS.folderPlan);
  });

  it("truncates active section headings", () => {
    const normalized = normalizeSendMessageRequest({
      content: "update section",
      activeSection: "h".repeat(600),
      chatMode: "agent",
    });
    expect(normalized.activeSection?.length).toBe(CHAT_REQUEST_LIMITS.activeSection);
  });
});
