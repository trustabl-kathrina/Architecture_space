import type { FolderPlanAgentInputs, SectionContext, ScopeKind } from "@/shared/types/chat";

function mapAgentInputs(raw: Record<string, unknown> | null | undefined): FolderPlanAgentInputs | null {
  if (!raw || typeof raw !== "object") {
    return null;
  }
  return {
    pipelineMode: raw.pipeline_mode ? String(raw.pipeline_mode) : null,
    researcher: raw.researcher ? String(raw.researcher) : null,
    analyst: raw.analyst ? String(raw.analyst) : null,
    domainExpert: raw.domain_expert ? String(raw.domain_expert) : null,
  };
}

export function mapSectionContext(raw: Record<string, unknown>): SectionContext {
  return {
    scopeKind: raw.scope_kind as ScopeKind,
    scopePath: String(raw.scope_path ?? ""),
    updatedAt: String(raw.updated_at),
    lastPlanSummary: raw.last_plan_summary ? String(raw.last_plan_summary) : null,
    lastPlanExplanation: raw.last_plan_explanation ? String(raw.last_plan_explanation) : null,
    lastTargetStructure: raw.last_target_structure ? String(raw.last_target_structure) : null,
    lastAgentInputs: mapAgentInputs(raw.last_agent_inputs as Record<string, unknown> | undefined),
    lineage: Array.isArray(raw.lineage)
      ? raw.lineage.map((event) => {
          const item = event as Record<string, unknown>;
          return {
            id: String(item.id),
            chatMode: item.chat_mode as SectionContext["lineage"][0]["chatMode"],
            eventType: item.event_type as SectionContext["lineage"][0]["eventType"],
            agent: item.agent ? (item.agent as SectionContext["lineage"][0]["agent"]) : null,
            summary: String(item.summary ?? ""),
            detail: String(item.detail ?? ""),
            timestamp: String(item.timestamp),
          };
        })
      : [],
  };
}
