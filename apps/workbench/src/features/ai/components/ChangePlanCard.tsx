import { MarkdownPreview } from "@/features/editor/components/MarkdownPreview";
import { planChangeUnits } from "@/features/editor/lib/applyHunks";
import { normalizeMarkdownText } from "@/features/editor/lib/normalizeMarkdown";
import type { ChangePlan, ChangePlanHunk } from "@/shared/types/chat";
import { cn } from "@/shared/utils/cn";

interface ChangePlanCardProps {
  plan: ChangePlan;
  acceptedChangeIds: Record<string, boolean>;
  acceptedCount: number;
  isCommitting: boolean;
  isRestoring: boolean;
  error?: Error | null;
  onToggleAccept: (changeId: string) => void;
  onAcceptAll: () => void;
  onRejectAll: () => void;
  onCommit: () => void;
  onRestore: () => void;
}

function hunkLabel(hunk: ChangePlanHunk): string {
  if (hunk.type === "insert") {
    return `+ line ${hunk.startLine}`;
  }
  if (hunk.type === "delete") {
    return `− lines ${hunk.startLine}–${hunk.endLine}`;
  }
  return `~ lines ${hunk.startLine}–${hunk.endLine}`;
}

export function ChangePlanCard({
  plan,
  acceptedChangeIds,
  acceptedCount,
  isCommitting,
  isRestoring,
  error,
  onToggleAccept,
  onAcceptAll,
  onRejectAll,
  onCommit,
  onRestore,
}: ChangePlanCardProps) {
  const busy = isCommitting || isRestoring;
  const hunks = planChangeUnits(plan).filter(
    (unit): unit is ChangePlanHunk => "type" in unit,
  );
  const hasHunks = hunks.length > 0;
  const canCommit = !hasHunks || acceptedCount > 0;

  return (
    <div className="rounded-2xl border border-border/60 bg-surface p-4 text-sm">
      <div className="mb-3 flex items-start justify-between gap-3">
        <div className="min-w-0">
          <p className="font-medium text-content">{plan.summary}</p>
          <p className="mt-1 font-mono text-[10px] text-content-subtle">
            pending review · {hasHunks ? `${acceptedCount}/${hunks.length} accepted` : "full file"}
          </p>
        </div>
        <span className="shrink-0 rounded-full bg-amber-500/15 px-2.5 py-0.5 text-[10px] font-medium text-amber-300">
          not on disk
        </span>
      </div>

      <div className="prose-chat mb-3 text-xs leading-relaxed text-content-muted">
        <MarkdownPreview content={normalizeMarkdownText(plan.explanation)} />
      </div>

      {hasHunks ? (
        <div className="mb-3 max-h-36 space-y-1 overflow-y-auto rounded-xl bg-surface-overlay/60 p-2">
          {hunks.map((hunk) => {
            const accepted = acceptedChangeIds[hunk.id] ?? false;
            return (
              <div
                key={hunk.id}
                className={cn(
                  "flex w-full items-center gap-2 rounded-lg px-2 py-1.5 text-left text-xs",
                  accepted ? "bg-emerald-500/10" : "opacity-80",
                )}
              >
                <span className="min-w-0 flex-1 truncate font-medium text-content">
                  {hunkLabel(hunk)}
                </span>
                <button
                  type="button"
                  className={cn(
                    "rounded px-1.5 py-0.5 text-[10px]",
                    accepted ? "text-emerald-300" : "text-content-subtle hover:text-content",
                  )}
                  disabled={busy}
                  onClick={() => onToggleAccept(hunk.id)}
                >
                  {accepted ? "accepted" : "accept"}
                </button>
              </div>
            );
          })}
        </div>
      ) : null}

      {error ? (
        <p className="mb-2 rounded-lg bg-red-500/10 px-2 py-1 text-xs text-red-400">{error.message}</p>
      ) : null}

      <div className="mb-2 flex gap-2">
        {hasHunks ? (
          <>
            <button type="button" className="btn-secondary flex-1 text-xs" disabled={busy} onClick={onAcceptAll}>
              Accept all
            </button>
            <button type="button" className="btn-secondary flex-1 text-xs" disabled={busy} onClick={onRejectAll}>
              Reject all
            </button>
          </>
        ) : null}
      </div>

      <div className="flex gap-2">
        <button
          type="button"
          className={cn("btn-primary flex-1 text-xs", (!canCommit || busy) && "opacity-50")}
          disabled={!canCommit || busy}
          onClick={onCommit}
        >
          {isCommitting ? "Committing…" : "Commit to disk"}
        </button>
        <button type="button" className="btn-secondary flex-1 text-xs" disabled={busy} onClick={onRestore}>
          {isRestoring ? "Discarding…" : "Discard"}
        </button>
      </div>
    </div>
  );
}
