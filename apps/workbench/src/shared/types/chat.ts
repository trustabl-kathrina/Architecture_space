export type ChatIntent =
  | "advise"
  | "suggest"
  | "generate_section"
  | "expand"
  | "improve";

export type AgentName = "orchestrator" | "planner" | "advisor" | "editor";

export type AgentStepStatus = "pending" | "running" | "completed" | "skipped" | "failed";

export type ChangePlanStatus = "pending" | "applied" | "discarded";

export type ChangePlanHunkType = "insert" | "replace" | "delete";

export type SectionChangeType = "new" | "modified" | "deleted";

export interface AgentExecutionStep {
  id: string;
  agent: AgentName;
  label: string;
  status: AgentStepStatus;
  detail: string;
  targetPath?: string | null;
  timestamp: string;
}

export interface SectionChange {
  id: string;
  changeType: SectionChangeType;
  sectionTitle: string;
  sectionPath: string;
  headingLevel: number;
  original: string;
  proposed: string;
  startLine: number;
}

export interface ChangePlanHunk {
  id: string;
  type: ChangePlanHunkType;
  startLine: number;
  endLine: number;
  original: string;
  proposed: string;
}

export interface ChangePlan {
  editId: string;
  documentPath: string;
  baseChecksum: string;
  baseBody: string;
  intent: ChatIntent;
  summary: string;
  explanation: string;
  sections: SectionChange[];
  hunks: ChangePlanHunk[];
  proposedBody: string;
  confidence: number;
  status: ChangePlanStatus;
  createdAt: string;
}

export interface ChatMessage {
  id: string;
  role: "user" | "assistant";
  content: string;
  timestamp: string;
  intent?: ChatIntent | null;
  changePlanId?: string | null;
  executionTrail?: AgentExecutionStep[];
}

export interface Conversation {
  id: string;
  documentPath: string | null;
  createdAt: string;
  updatedAt: string;
  messages: ChatMessage[];
}

export interface SendMessageRequest {
  content: string;
  documentPath?: string | null;
  selection?: string | null;
  openPaths?: string[];
  activeSection?: string | null;
  documentOutline?: string[];
}

export interface SendMessageResponse {
  message: ChatMessage;
  changePlan: ChangePlan | null;
  userMessage?: ChatMessage | null;
}

export type ChatStreamEventType =
  | "status"
  | "execution_plan"
  | "trail_step"
  | "agent_thought"
  | "assistant_delta"
  | "done"
  | "error";

export interface AgentThought {
  agent: AgentName;
  text: string;
}

export interface ChatStreamEvent {
  type: ChatStreamEventType;
  message?: string | null;
  agent?: AgentName | null;
  step?: AgentExecutionStep | null;
  steps?: AgentExecutionStep[] | null;
  content?: string | null;
  response?: SendMessageResponse | null;
}

export interface StreamingTurn {
  userText: string;
  status: string | null;
  trail: AgentExecutionStep[];
  agentThoughts: AgentThought[];
  assistantText: string;
  error?: string | null;
  failed?: boolean;
}

export interface ApplyChangePlanRequest {
  acceptedHunkIds?: string[] | null;
}

export interface ApplyChangePlanResponse {
  editId: string;
  documentPath: string;
  checksum: string;
  applied: boolean;
  diskPath?: string | null;
}
