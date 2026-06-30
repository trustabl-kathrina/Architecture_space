import type { SectionContext } from "@/shared/types/chat";

interface SectionLineageBannerProps {
  context: SectionContext | null;
  chatMode: "plan" | "agent";
}

export function SectionLineageBanner({ context, chatMode }: SectionLineageBannerProps) {
  if (!context) {
    return null;
  }

  const hasPlan = Boolean(context.lastPlanSummary);
  const recent = context.lineage.slice(-3);

  if (!hasPlan && recent.length === 0) {
    return null;
  }

  return (
    <div className="mx-4 mt-3 rounded-xl border border-border/50 bg-surface-overlay/50 px-3 py-2.5 text-[11px] leading-relaxed text-content-muted">
      <p className="font-medium text-content">
        {chatMode === "agent" ? "Agent mode" : "Plan mode"} · shared section context
      </p>
      {hasPlan ? (
        <p className="mt-1">
          <span className="text-content-subtle">Last plan: </span>
          {context.lastPlanSummary}
        </p>
      ) : null}
      {recent.length > 0 ? (
        <ul className="mt-1.5 space-y-0.5 text-content-subtle">
          {recent.map((event) => (
            <li key={event.id}>
              [{event.chatMode}] {event.eventType}: {event.summary}
            </li>
          ))}
        </ul>
      ) : null}
      {chatMode === "agent" && hasPlan ? (
        <p className="mt-1.5 text-content-subtle">
          Plan recommendations are available — ask to implement reorganization items or edit open
          files.
        </p>
      ) : null}
    </div>
  );
}
