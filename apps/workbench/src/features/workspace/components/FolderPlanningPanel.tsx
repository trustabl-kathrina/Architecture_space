import { useState } from "react";
import { useQuery } from "@tanstack/react-query";

import { chatKeys, fetchSectionContext } from "@/features/ai/api/chatApi";
import { FolderContentsList } from "@/features/workspace/components/FolderContentsList";
import { useFolderPlanStore } from "@/features/workspace/stores/folderPlanStore";
import { cn } from "@/shared/utils/cn";

interface FolderPlanningPanelProps {
  folderPath: string;
}

function formatBreadcrumb(path: string): string[] {
  if (!path) {
    return ["docs"];
  }
  return ["docs", ...path.split("/").filter(Boolean)];
}

function pipelineModeLabel(mode: string | null | undefined): string {
  switch (mode) {
    case "refine_draft":
      return "Refine draft (Planner only)";
    case "quick":
      return "Quick plan (Planner only)";
    case "full":
      return "Full pipeline (Researcher → Analyst → Domain expert → Planner)";
    default:
      return "Planner — structure author";
  }
}

export function FolderPlanningPanel({ folderPath }: FolderPlanningPanelProps) {
  const plan = useFolderPlanStore((s) => s.getPlan(folderPath));
  const setPlan = useFolderPlanStore((s) => s.setPlan);
  const [agentInputsOpen, setAgentInputsOpen] = useState(false);
  const crumbs = formatBreadcrumb(folderPath);
  const displayName = folderPath.split("/").pop() || "docs";

  const sectionContextQuery = useQuery({
    queryKey: chatKeys.sectionContext("folder", folderPath),
    queryFn: () => fetchSectionContext("folder", folderPath),
    staleTime: 15_000,
  });

  const agentInputs = sectionContextQuery.data?.lastAgentInputs;
  const hasAgentInputs = Boolean(
    agentInputs?.researcher || agentInputs?.analyst || agentInputs?.domainExpert,
  );

  return (
    <div className="flex h-full min-w-0 flex-col">
      <header className="shrink-0 border-b border-border/50 px-5 py-4">
        <p className="text-[11px] font-medium uppercase tracking-wide text-content-subtle">
          Section planner
        </p>
        <h1 className="mt-1 truncate text-lg font-medium text-content">{displayName}</h1>
        <nav aria-label="Folder breadcrumb" className="mt-2 flex flex-wrap items-center gap-1">
          {crumbs.map((crumb, index) => (
            <span key={`${crumb}-${index}`} className="flex items-center gap-1 text-xs text-content-muted">
              {index > 0 ? <span className="text-content-subtle/50">/</span> : null}
              <span className={cn(index === crumbs.length - 1 && "text-content")}>{crumb}</span>
            </span>
          ))}
        </nav>
      </header>

      <div className="grid min-h-0 flex-1 grid-cols-1 lg:grid-cols-[minmax(220px,32%)_1fr]">
        <FolderContentsList
          folderPath={folderPath}
          className="border-b border-border/40 lg:border-b-0 lg:border-r"
        />

        <section className="flex min-h-0 flex-col" aria-label="Structure plan">
          <header className="shrink-0 border-b border-border/40 px-4 py-2.5">
            <h2 className="text-xs font-medium uppercase tracking-wide text-content-subtle">
              Planned structure
            </h2>
            <p className="mt-0.5 text-[11px] leading-relaxed text-content-muted">
              Structure is authored by the <strong className="font-medium text-content">Planner</strong>{" "}
              agent (synthesis of Researcher, Analyst, and Domain expert when full pipeline runs).
              Draft here first, then refine in Plan mode chat.
            </p>
            {agentInputs?.pipelineMode ? (
              <p className="mt-1 text-[10px] uppercase tracking-wide text-content-subtle">
                Last run: {pipelineModeLabel(agentInputs.pipelineMode)}
              </p>
            ) : null}
          </header>

          {hasAgentInputs ? (
            <div className="shrink-0 border-b border-border/40 px-4 py-2">
              <button
                type="button"
                onClick={() => setAgentInputsOpen((open) => !open)}
                className="text-[11px] font-medium text-content-muted hover:text-content"
              >
                {agentInputsOpen ? "Hide" : "Show"} agent inputs
              </button>
              {agentInputsOpen ? (
                <div className="mt-2 max-h-40 space-y-2 overflow-y-auto text-[11px] leading-relaxed text-content-muted">
                  {agentInputs?.researcher ? (
                    <div>
                      <p className="font-medium text-content-subtle">Researcher</p>
                      <p className="whitespace-pre-wrap">{agentInputs.researcher}</p>
                    </div>
                  ) : null}
                  {agentInputs?.analyst ? (
                    <div>
                      <p className="font-medium text-content-subtle">Analyst</p>
                      <p className="whitespace-pre-wrap">{agentInputs.analyst}</p>
                    </div>
                  ) : null}
                  {agentInputs?.domainExpert ? (
                    <div>
                      <p className="font-medium text-content-subtle">Domain expert</p>
                      <p className="whitespace-pre-wrap">{agentInputs.domainExpert}</p>
                    </div>
                  ) : null}
                </div>
              ) : null}
            </div>
          ) : null}

          <div className="relative min-h-0 flex-1">
            <textarea
              value={plan}
              onChange={(event) => setPlan(folderPath, event.target.value)}
              placeholder={`Example:\n\n02_Semantic_Modeling/\n├── 01_Business_Glossary.md\n├── 02_Metrics_Layer.md\n├── 03_Semantic_Layer.md\n└── README.md\n\n## Notes\n- Glossary-first semantics pipeline\n- Link glossary terms to each topic`}
              className="h-full w-full resize-none bg-transparent px-4 py-4 font-mono text-[13px] leading-relaxed text-content placeholder:text-content-subtle focus:outline-none"
              spellCheck={false}
            />
          </div>

          <footer className="shrink-0 border-t border-border/40 px-4 py-2 text-[11px] text-content-subtle">
            Saved locally · {plan.length > 0 ? `${plan.split("\n").length} lines` : "empty plan"}
          </footer>
        </section>
      </div>
    </div>
  );
}
