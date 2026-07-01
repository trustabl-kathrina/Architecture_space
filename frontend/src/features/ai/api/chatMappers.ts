import type {
  AgentExecutionStep,
  ChangePlan,
  ChangePlanHunk,
  ChatMessage,
  Conversation,
  FolderPlanResult,
  FolderReorganizationItem,
  SectionChange,
  SendMessageResponse,
} from "@/shared/types/chat";

function mapSection(raw: Record<string, unknown>): SectionChange {
  return {
    id: String(raw.id),
    changeType: raw.change_type as SectionChange["changeType"],
    sectionTitle: String(raw.section_title ?? ""),
    sectionPath: String(raw.section_path ?? ""),
    headingLevel: Number(raw.heading_level ?? 0),
    original: String(raw.original ?? ""),
    proposed: String(raw.proposed ?? ""),
    startLine: Number(raw.start_line ?? 1),
  };
}

function mapHunk(raw: Record<string, unknown>): ChangePlanHunk {
  return {
    id: String(raw.id),
    type: raw.type as ChangePlanHunk["type"],
    startLine: Number(raw.start_line),
    endLine: Number(raw.end_line),
    original: String(raw.original ?? ""),
    proposed: String(raw.proposed ?? ""),
  };
}

export function mapExecutionStep(raw: Record<string, unknown>): AgentExecutionStep {
  return {
    id: String(raw.id),
    agent: raw.agent as AgentExecutionStep["agent"],
    label: String(raw.label),
    status: raw.status as AgentExecutionStep["status"],
    detail: String(raw.detail ?? ""),
    targetPath: raw.target_path ? String(raw.target_path) : null,
    timestamp: String(raw.timestamp),
  };
}

export function mapChangePlan(raw: Record<string, unknown>): ChangePlan {
  return {
    editId: String(raw.edit_id),
    documentPath: String(raw.document_path),
    baseChecksum: String(raw.base_checksum),
    baseBody: String(raw.base_body ?? ""),
    intent: raw.intent as ChangePlan["intent"],
    summary: String(raw.summary),
    explanation: String(raw.explanation),
    sections: Array.isArray(raw.sections)
      ? raw.sections.map((section) => mapSection(section as Record<string, unknown>))
      : [],
    hunks: Array.isArray(raw.hunks)
      ? raw.hunks.map((hunk) => mapHunk(hunk as Record<string, unknown>))
      : [],
    proposedBody: String(raw.proposed_body),
    confidence: Number(raw.confidence),
    status: raw.status as ChangePlan["status"],
    createdAt: String(raw.created_at),
  };
}

export function mapChatMessage(raw: Record<string, unknown>): ChatMessage {
  return {
    id: String(raw.id),
    role: raw.role as ChatMessage["role"],
    content: String(raw.content),
    timestamp: String(raw.timestamp),
    chatMode: raw.chat_mode ? (raw.chat_mode as ChatMessage["chatMode"]) : null,
    intent: (raw.intent as ChatMessage["intent"]) ?? null,
    changePlanId: raw.change_plan_id ? String(raw.change_plan_id) : null,
    executionTrail: Array.isArray(raw.execution_trail)
      ? raw.execution_trail.map((step) => mapExecutionStep(step as Record<string, unknown>))
      : [],
  };
}

export function mapConversation(raw: Record<string, unknown>): Conversation {
  return {
    id: String(raw.id),
    scopeKind: raw.scope_kind ? (raw.scope_kind as Conversation["scopeKind"]) : null,
    scopePath: raw.scope_path != null ? String(raw.scope_path) : null,
    chatMode: raw.chat_mode ? (raw.chat_mode as Conversation["chatMode"]) : null,
    documentPath: raw.document_path ? String(raw.document_path) : null,
    createdAt: String(raw.created_at),
    updatedAt: String(raw.updated_at),
    messages: Array.isArray(raw.messages)
      ? raw.messages.map((message) => mapChatMessage(message as Record<string, unknown>))
      : [],
  };
}

function mapFolderReorganizationItem(raw: Record<string, unknown>): FolderReorganizationItem {
  return {
    action: raw.action as FolderReorganizationItem["action"],
    path: String(raw.path ?? ""),
    targetPath: raw.target_path ? String(raw.target_path) : null,
    rationale: String(raw.rationale ?? ""),
  };
}

export function mapFolderPlanResult(raw: Record<string, unknown>): FolderPlanResult {
  return {
    summary: String(raw.summary ?? ""),
    explanation: String(raw.explanation ?? ""),
    targetStructure: String(raw.target_structure ?? ""),
    reorganization: Array.isArray(raw.reorganization)
      ? raw.reorganization.map((item) =>
          mapFolderReorganizationItem(item as Record<string, unknown>),
        )
      : [],
    confidence: Number(raw.confidence ?? 0),
  };
}

export function mapSendMessageResponse(raw: Record<string, unknown>): SendMessageResponse {
  return {
    message: mapChatMessage(raw.message as Record<string, unknown>),
    changePlan: raw.change_plan
      ? mapChangePlan(raw.change_plan as Record<string, unknown>)
      : null,
    folderPlanResult: raw.folder_plan_result
      ? mapFolderPlanResult(raw.folder_plan_result as Record<string, unknown>)
      : null,
    userMessage: raw.user_message
      ? mapChatMessage(raw.user_message as Record<string, unknown>)
      : null,
  };
}
