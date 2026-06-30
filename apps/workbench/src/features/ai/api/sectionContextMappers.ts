import type { SectionContext, ScopeKind } from "@/shared/types/chat";

export function mapSectionContext(raw: Record<string, unknown>): SectionContext {
  return {
    scopeKind: raw.scope_kind as ScopeKind,
    scopePath: String(raw.scope_path ?? ""),
    updatedAt: String(raw.updated_at),
    lastPlanSummary: raw.last_plan_summary ? String(raw.last_plan_summary) : null,
    lastPlanExplanation: raw.last_plan_explanation ? String(raw.last_plan_explanation) : null,
    lastTargetStructure: raw.last_target_structure ? String(raw.last_target_structure) : null,
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
