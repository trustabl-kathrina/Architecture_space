import type { AgentExecutionStep, AgentThought } from "@/shared/types/chat";
import { cn } from "@/shared/utils/cn";

const AGENT_LABELS: Record<AgentExecutionStep["agent"], string> = {
  orchestrator: "Orchestrator",
  planner: "Planner",
  advisor: "Advisor",
  editor: "Editor",
};

const AGENT_STYLES: Record<AgentExecutionStep["agent"], string> = {
  orchestrator: "bg-blue-500/15 text-blue-300",
  planner: "bg-violet-500/15 text-violet-300",
  advisor: "bg-emerald-500/15 text-emerald-300",
  editor: "bg-amber-500/15 text-amber-300",
};

function StepStatusIcon({ status }: { status: AgentExecutionStep["status"] }) {
  if (status === "running") {
    return (
      <span className="inline-flex h-4 w-4 items-center justify-center">
        <span className="h-3 w-3 animate-spin rounded-full border-2 border-content-subtle border-t-accent" />
      </span>
    );
  }
  if (status === "completed") {
    return <span className="text-emerald-400">✓</span>;
  }
  if (status === "failed") {
    return <span className="text-red-400">✕</span>;
  }
  if (status === "skipped") {
    return <span className="text-content-subtle">–</span>;
  }
  return <span className="h-2 w-2 rounded-full bg-content-subtle/60" />;
}

interface ExecutionTrailPanelProps {
  trail: AgentExecutionStep[];
  agentThoughts?: AgentThought[];
  statusLine?: string | null;
  error?: string | null;
  defaultOpen?: boolean;
  isLive?: boolean;
}

export function ExecutionTrailPanel({
  trail,
  agentThoughts = [],
  statusLine = null,
  error = null,
  defaultOpen = false,
  isLive = false,
}: ExecutionTrailPanelProps) {
  if (trail.length === 0 && !isLive && !statusLine && !error && agentThoughts.length === 0) {
    return null;
  }

  const completedCount = trail.filter((step) => step.status === "completed").length;
  const runningStep = trail.find((step) => step.status === "running");
  const failedStep = trail.find((step) => step.status === "failed");

  return (
    <div className="mb-2 w-full rounded-xl border border-border/50 bg-surface-overlay/40 text-xs">
      <div className="flex items-center justify-between gap-2 px-3 py-2">
        <p className="font-medium text-content-muted">Agent workflow</p>
        {trail.length > 0 ? (
          <span className="text-content-subtle">
            {completedCount}/{trail.length} done
          </span>
        ) : null}
      </div>

      {statusLine ? (
        <p className="border-t border-border/40 px-3 py-2 text-content-subtle">{statusLine}</p>
      ) : null}

      {runningStep ? (
        <p className="border-t border-border/40 px-3 py-2 text-content">
          Running: <span className="font-medium">{AGENT_LABELS[runningStep.agent]}</span>
          {" · "}
          {runningStep.label}
        </p>
      ) : null}

      {trail.length > 0 ? (
        <ol className="space-y-0 border-t border-border/40">
          {trail.map((step, index) => (
            <li
              key={step.id}
              className={cn(
                "flex gap-2.5 px-3 py-2.5",
                index < trail.length - 1 && "border-b border-border/30",
                step.status === "running" && "bg-accent/5",
                step.status === "failed" && "bg-red-500/5",
              )}
            >
              <span className="mt-0.5 flex h-4 w-4 shrink-0 items-center justify-center text-[11px]">
                <StepStatusIcon status={step.status} />
              </span>
              <span
                className={cn(
                  "mt-0.5 flex h-5 shrink-0 items-center rounded px-1.5 text-[10px] font-medium uppercase tracking-wide",
                  AGENT_STYLES[step.agent],
                )}
              >
                {AGENT_LABELS[step.agent]}
              </span>
              <div className="min-w-0 flex-1">
                <p
                  className={cn(
                    "font-medium",
                    step.status === "pending" && "text-content-subtle",
                    step.status === "running" && "text-content",
                    step.status === "completed" && "text-content",
                    step.status === "failed" && "text-red-300",
                    step.status === "skipped" && "text-content-muted",
                  )}
                >
                  {step.label}
                </p>
                {step.detail ? (
                  <p className="mt-0.5 whitespace-pre-wrap leading-relaxed text-content-muted">
                    {step.detail}
                  </p>
                ) : null}
                {step.targetPath ? (
                  <p className="mt-1 truncate text-[10px] text-content-subtle">{step.targetPath}</p>
                ) : null}
              </div>
            </li>
          ))}
        </ol>
      ) : null}

      {agentThoughts.length > 0 ? (
        <div className="space-y-2 border-t border-border/40 px-3 py-2">
          <p className="text-[10px] font-medium uppercase tracking-wide text-content-subtle">
            Agent reasoning (live)
          </p>
          {agentThoughts.map((thought, index) => (
            <div
              key={`${thought.agent}-${index}`}
              className="rounded-lg border border-border/40 bg-surface/60 p-2"
            >
              <p className={cn("mb-1 text-[10px] font-medium uppercase", AGENT_STYLES[thought.agent])}>
                {AGENT_LABELS[thought.agent]}
              </p>
              <p className="whitespace-pre-wrap leading-relaxed text-content-muted">{thought.text}</p>
            </div>
          ))}
        </div>
      ) : null}

      {error ? (
        <p className="border-t border-red-500/20 bg-red-500/10 px-3 py-2 text-red-300">{error}</p>
      ) : null}

      {failedStep && !error ? (
        <p className="border-t border-red-500/20 bg-red-500/10 px-3 py-2 text-red-300">
          Failed at {AGENT_LABELS[failedStep.agent]}: {failedStep.detail || failedStep.label}
        </p>
      ) : null}

      {isLive && !statusLine && !runningStep && trail.length === 0 ? (
        <div className="flex items-center gap-2 border-t border-border/40 px-3 py-2 text-content-subtle">
          <span className="inline-flex gap-1">
            <span className="h-1.5 w-1.5 animate-pulse rounded-full bg-content-subtle" />
            <span className="h-1.5 w-1.5 animate-pulse rounded-full bg-content-subtle [animation-delay:150ms]" />
            <span className="h-1.5 w-1.5 animate-pulse rounded-full bg-content-subtle [animation-delay:300ms]" />
          </span>
          Starting workflow…
        </div>
      ) : null}
    </div>
  );
}
