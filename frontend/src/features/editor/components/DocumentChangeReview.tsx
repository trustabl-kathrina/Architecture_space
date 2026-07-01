import { MarkdownPreview } from "@/features/editor/components/MarkdownPreview";
import {
  buildDiffLines,
  planChangeUnits,
} from "@/features/editor/lib/applyHunks";
import { normalizeMarkdownText } from "@/features/editor/lib/normalizeMarkdown";
import type { ChangePlan, ChangePlanHunk } from "@/shared/types/chat";
import { cn } from "@/shared/utils/cn";

interface DocumentChangeReviewProps {
  plan: ChangePlan;
  originalBody: string;
  previewBody: string;
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
    return `Insert at line ${hunk.startLine}`;
  }
  if (hunk.type === "delete") {
    return `Delete lines ${hunk.startLine}–${hunk.endLine}`;
  }
  return `Replace lines ${hunk.startLine}–${hunk.endLine}`;
}

export function DocumentChangeReview({
  plan,
  originalBody,
  previewBody,
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
}: DocumentChangeReviewProps) {
  const busy = isCommitting || isRestoring;
  const diffLines = buildDiffLines(originalBody, previewBody);
  const hunks = planChangeUnits(plan).filter(
    (unit): unit is ChangePlanHunk => "type" in unit,
  );
  const hasHunks = hunks.length > 0;
  const canCommit = !hasHunks || acceptedCount > 0;

  return (
    <div className="flex h-full min-h-0 flex-col">
      <header className="flex shrink-0 flex-wrap items-center justify-between gap-3 border-b border-border/50 bg-surface-overlay/80 px-4 py-3">
        <div className="min-w-0">
          <p className="text-sm font-medium text-content">Review changes</p>
          <p className="mt-0.5 font-mono text-[11px] text-content-subtle">
            on disk → with accepted blocks · {plan.summary}
          </p>
          <p className="mt-1 text-xs text-content-muted">
            {hasHunks
              ? `${acceptedCount}/${hunks.length} change block(s) accepted`
              : "Full file replacement"}
          </p>
        </div>
        <div className="flex flex-wrap items-center gap-2">
          {hasHunks ? (
            <>
              <button type="button" className="btn-secondary text-xs" disabled={busy} onClick={onAcceptAll}>
                Accept all
              </button>
              <button type="button" className="btn-secondary text-xs" disabled={busy} onClick={onRejectAll}>
                Reject all
              </button>
            </>
          ) : null}
          <button
            type="button"
            className={cn("btn-primary text-xs", (!canCommit || busy) && "opacity-50")}
            disabled={!canCommit || busy}
            onClick={onCommit}
            title="Write accepted changes to disk"
          >
            {isCommitting ? "Committing…" : "Commit to disk"}
          </button>
          <button
            type="button"
            className="btn-secondary text-xs"
            disabled={busy}
            onClick={onRestore}
            title="Discard all proposed changes"
          >
            {isRestoring ? "Restoring…" : "Discard"}
          </button>
        </div>
      </header>

      {error ? (
        <p className="shrink-0 border-b border-red-500/20 bg-red-500/10 px-4 py-2 text-xs text-red-400">
          {error.message}
        </p>
      ) : null}

      <div className="grid min-h-0 flex-1 grid-cols-1 xl:grid-cols-2">
        <section className="min-h-0 overflow-y-auto border-b border-border/50 xl:border-b-0 xl:border-r">
          <div className="grid grid-cols-2 border-b border-border/40 bg-surface-raised/95 text-[10px] font-medium uppercase tracking-wide text-content-subtle">
            <div className="border-r border-border/40 px-4 py-2">On disk</div>
            <div className="px-4 py-2">With accepted blocks</div>
          </div>

          <div className="grid min-h-[12rem] grid-cols-2">
            <div className="border-r border-border/40 p-3">
              <pre className="whitespace-pre-wrap font-mono text-[11px] text-content-muted">
                {originalBody.trim() || "(empty file body)"}
              </pre>
            </div>
            <div className="p-3">
              <pre className="whitespace-pre-wrap font-mono text-[11px] text-content">
                {previewBody.trim() || "(no accepted changes yet)"}
              </pre>
            </div>
          </div>

          <div className="border-t border-border/40 px-4 py-2 text-xs font-medium text-content-muted">
            Change blocks
          </div>
          <div className="space-y-2 p-3">
            {!hasHunks ? (
              <p className="rounded-xl bg-surface-overlay/60 p-3 text-xs text-content-muted">
                Commit writes the full proposed body to disk. Discard keeps the file unchanged.
              </p>
            ) : (
              hunks.map((hunk) => {
                const accepted = acceptedChangeIds[hunk.id] ?? false;
                const label = hunkLabel(hunk);
                return (
                  <div
                    key={hunk.id}
                    className={cn(
                      "rounded-xl border p-3 transition-colors",
                      accepted
                        ? "border-emerald-500/30 bg-emerald-500/5"
                        : "border-border/50 bg-surface-overlay/30",
                    )}
                  >
                    <div className="mb-2 flex flex-wrap items-center gap-2">
                      <span className="font-mono text-[11px] font-medium text-content">{label}</span>
                      <div className="ml-auto flex gap-1">
                        <button
                          type="button"
                          className={cn(
                            "rounded px-2 py-0.5 text-[10px] font-medium",
                            accepted
                              ? "bg-emerald-500/20 text-emerald-200"
                              : "bg-surface-raised text-content-subtle hover:text-content",
                          )}
                          disabled={busy || accepted}
                          onClick={() => onToggleAccept(hunk.id)}
                        >
                          Accept
                        </button>
                        <button
                          type="button"
                          className={cn(
                            "rounded px-2 py-0.5 text-[10px] font-medium",
                            !accepted
                              ? "bg-red-500/15 text-red-300"
                              : "bg-surface-raised text-content-subtle hover:text-content",
                          )}
                          disabled={busy || !accepted}
                          onClick={() => onToggleAccept(hunk.id)}
                        >
                          Reject
                        </button>
                      </div>
                    </div>
                    {hunk.original ? (
                      <pre className="mb-2 whitespace-pre-wrap rounded-lg border border-red-500/20 bg-red-500/5 p-2 font-mono text-[11px] text-red-300/90">
                        − {hunk.original}
                      </pre>
                    ) : null}
                    {hunk.proposed ? (
                      <div className="prose-chat rounded-lg border border-emerald-500/20 bg-emerald-500/5 p-2 text-[11px]">
                        <MarkdownPreview content={normalizeMarkdownText(hunk.proposed)} />
                      </div>
                    ) : null}
                  </div>
                );
              })
            )}
          </div>
        </section>

        <section className="min-h-0 overflow-y-auto">
          <div className="sticky top-0 z-10 border-b border-border/40 bg-surface-raised/95 px-4 py-2 font-mono text-[10px] font-medium uppercase tracking-wide text-content-muted">
            diff (disk → accepted)
          </div>
          <div className="font-mono text-[11px] leading-5">
            {diffLines.length === 0 ? (
              <p className="p-4 text-xs text-content-subtle">No diff — accepted result matches disk.</p>
            ) : (
              diffLines.map((line, index) => (
                <div
                  key={`${line.type}-${index}`}
                  className={cn(
                    "grid grid-cols-[3rem_3rem_1fr] gap-2 border-b border-border/20 px-3 py-0.5",
                    line.type === "add" && "bg-emerald-500/10",
                    line.type === "remove" && "bg-red-500/10",
                  )}
                >
                  <span className="text-right text-content-subtle">{line.oldLine ?? ""}</span>
                  <span className="text-right text-content-subtle">{line.newLine ?? ""}</span>
                  <span
                    className={cn(
                      "whitespace-pre-wrap break-words",
                      line.type === "add" && "text-emerald-300",
                      line.type === "remove" && "text-red-300",
                      line.type === "context" && "text-content-muted",
                    )}
                  >
                    {line.type === "add" ? "+ " : line.type === "remove" ? "- " : "  "}
                    {line.text || " "}
                  </span>
                </div>
              ))
            )}
          </div>
        </section>
      </div>

      <footer className="shrink-0 border-t border-border/50 px-4 py-2 text-center text-[10px] text-content-subtle">
        Accept each change block individually, then Commit to disk. Nothing is written until you commit.
      </footer>
    </div>
  );
}
