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

export function FolderPlanningPanel({ folderPath }: FolderPlanningPanelProps) {
  const plan = useFolderPlanStore((s) => s.getPlan(folderPath));
  const setPlan = useFolderPlanStore((s) => s.setPlan);
  const crumbs = formatBreadcrumb(folderPath);
  const displayName = folderPath.split("/").pop() || "docs";

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
              Draft your target structure here first, then use Plan mode chat to refine it.
              Your edits and chat recommendations are sent to every planning agent.
            </p>
          </header>

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
