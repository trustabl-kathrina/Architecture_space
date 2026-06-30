export type ChatMode = "plan" | "agent";

export type ScopeKind = "file" | "folder";

export type ChatIntent =
  | "advise"
  | "suggest"
  | "generate_section"
  | "expand"
  | "improve";

export type AgentName =
  | "orchestrator"
  | "planner"
  | "advisor"
  | "editor"
  | "researcher"
  | "analyst"
  | "domain_expert";

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
  chatMode?: ChatMode | null;
  intent?: ChatIntent | null;
  changePlanId?: string | null;
  executionTrail?: AgentExecutionStep[];
}

export interface Conversation {
  id: string;
  scopeKind?: ScopeKind | null;
  scopePath?: string | null;
  chatMode?: ChatMode | null;
  documentPath: string | null;
  createdAt: string;
  updatedAt: string;
  messages: ChatMessage[];
}

export interface ResolveConversationRequest {
  scopeKind: ScopeKind;
  scopePath: string;
  chatMode: ChatMode;
}

export interface EditMessageRequest {
  content: string;
}

export interface SectionLineageEvent {
  id: string;
  chatMode: ChatMode;
  eventType: "folder_plan" | "advisory" | "change_plan" | "user_message";
  agent?: AgentName | null;
  summary: string;
  detail: string;
  timestamp: string;
}

export interface SectionContext {
  scopeKind: ScopeKind;
  scopePath: string;
  updatedAt: string;
  lastPlanSummary?: string | null;
  lastPlanExplanation?: string | null;
  lastTargetStructure?: string | null;
  lineage: SectionLineageEvent[];
}

export interface RegenerateMessageRequest {
  documentPath?: string | null;
  folderPath?: string | null;
  folderPlan?: string | null;
  folderContents?: string[];
  chatMode?: ChatMode;
  openPaths?: string[];
  activeSection?: string | null;
  documentOutline?: string[];
}

export interface SendMessageRequest {
  content: string;
  documentPath?: string | null;
  folderPath?: string | null;
  folderPlan?: string | null;
  folderContents?: string[];
  chatMode?: ChatMode;
  selection?: string | null;
  openPaths?: string[];
  activeSection?: string | null;
  documentOutline?: string[];
}

export interface FolderReorganizationItem {
  action:
    | "keep"
    | "rename"
    | "move"
    | "merge"
    | "split"
    | "create"
    | "archive"
    | "delete";
  path: string;
  targetPath?: string | null;
  rationale: string;
}

export interface FolderPlanResult {
  summary: string;
  explanation: string;
  targetStructure: string;
  reorganization: FolderReorganizationItem[];
  confidence: number;
}

export interface SendMessageResponse {
  message: ChatMessage;
  changePlan: ChangePlan | null;
  folderPlanResult?: FolderPlanResult | null;
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
