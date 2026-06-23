import type { ReactNode } from "react";

import { useChangeReview } from "@/features/ai/hooks/useChangeReview";
import { DocumentChangeReview } from "@/features/editor/components/DocumentChangeReview";
import { DocumentMetaBar } from "@/features/editor/components/DocumentMetaBar";
import { EditorTabBar } from "@/features/editor/components/EditorTabBar";
import { MarkdownPreview } from "@/features/editor/components/MarkdownPreview";
import { TiptapEditor } from "@/features/editor/components/TiptapEditor";
import { ViewModeToggle } from "@/features/editor/components/ViewModeToggle";
import { useDocument } from "@/features/editor/hooks/useDocument";
import { useEditorStore } from "@/features/editor/stores/editorStore";
import { useWorkspaceStore } from "@/features/workspace/stores/workspaceStore";
import { cn } from "@/shared/utils/cn";

function EmptyState({ children }: { children: ReactNode }) {
  return (
    <div className="flex h-full flex-col items-center justify-center px-8 text-center">
      <p className="text-sm text-content-muted">{children}</p>
    </div>
  );
}

export function CenterPanel() {
  const selectedPath = useWorkspaceStore((s) => s.selectedPath);
  const viewMode = useEditorStore((s) => s.viewMode);
  const changeReview = useChangeReview(selectedPath);
  const {
    isMarkdownFile,
    isLoading,
    isError,
    error,
    body,
    frontMatter,
    isDirty,
    isSaving,
    savedChecksum,
    onContentChange,
    saveNow,
    reloadFromDisk,
  } = useDocument(selectedPath);

  if (!selectedPath) {
    return <EmptyState>Select a document from the sidebar to begin editing.</EmptyState>;
  }

  if (!isMarkdownFile) {
    return <EmptyState>Only Markdown (.md) files can be edited in this workbench.</EmptyState>;
  }

  if (isLoading) {
    return <EmptyState>Loading from disk…</EmptyState>;
  }

  if (isError) {
    return (
      <div className="flex h-full items-center justify-center px-8 text-sm text-red-400">
        {error instanceof Error ? error.message : "Failed to load document"}
      </div>
    );
  }

  if (changeReview.isActive && changeReview.pendingPlan) {
    const baseBody = changeReview.pendingPlan.baseBody || body;
    const previewBody = changeReview.getPreviewBody(baseBody);
    return (
      <div className="flex h-full min-w-0 flex-col">
        <EditorTabBar />
        <DocumentChangeReview
          plan={changeReview.pendingPlan}
          originalBody={baseBody}
          previewBody={previewBody}
          acceptedChangeIds={changeReview.acceptedChangeIds}
          acceptedCount={changeReview.acceptedCount}
          isCommitting={changeReview.isCommitting}
          isRestoring={changeReview.isRestoring}
          error={changeReview.commitError instanceof Error ? changeReview.commitError : null}
          onToggleAccept={changeReview.toggleAccept}
          onAcceptAll={changeReview.acceptAll}
          onRejectAll={changeReview.rejectAll}
          onCommit={() => void changeReview.commitToDisk()}
          onRestore={() => void changeReview.restoreWorkingTree()}
        />
      </div>
    );
  }

  const showEditor = viewMode === "edit" || viewMode === "split";
  const showPreview = viewMode === "preview" || viewMode === "split";

  return (
    <div className="flex h-full min-w-0 flex-col">
      <EditorTabBar />
      <header className="flex h-11 shrink-0 items-center justify-between gap-4 border-b border-border/50 px-4">
        <ViewModeToggle />
        <div className="flex flex-wrap items-center gap-2">
          <span
            className={cn(
              "text-xs",
              isSaving ? "text-content-subtle" : isDirty ? "text-amber-400/90" : "text-emerald-400/90",
            )}
          >
            {isSaving ? "Writing…" : isDirty ? "Uncommitted edits" : "Matches disk"}
          </span>
          {changeReview.lastCommittedAt ? (
            <span className="max-w-[14rem] truncate text-[10px] text-content-subtle" title={changeReview.lastDiskPath ?? undefined}>
              Committed {changeReview.lastCommittedAt}
            </span>
          ) : null}
          <button type="button" className="btn-secondary text-xs" onClick={() => void reloadFromDisk()}>
            Reload from disk
          </button>
          <button
            type="button"
            className="btn-primary text-xs"
            disabled={!isDirty || isSaving}
            onClick={() => void saveNow()}
            title="Write editor changes to the file on disk (no autosave)"
          >
            Save to disk
          </button>
        </div>
      </header>

      <DocumentMetaBar frontMatter={frontMatter} body={body} />

      <div
        className={cn(
          "grid min-h-0 flex-1",
          viewMode === "split" ? "grid-cols-2" : "grid-cols-1",
        )}
      >
        {showEditor ? (
          <section
            className={cn(
              "relative min-h-0 overflow-y-auto",
              viewMode === "split" && "border-r border-border/50",
            )}
            aria-label="Markdown editor"
          >
            <TiptapEditor
              key={`${selectedPath}:${savedChecksum ?? "loading"}`}
              content={body}
              onChange={onContentChange}
            />
            {!body.trim() ? (
              <p className="pointer-events-none absolute inset-x-0 top-24 mx-auto max-w-3xl px-8 text-sm text-content-subtle">
                Loaded from disk. Edit, then Save to disk — no autosave.
              </p>
            ) : null}
          </section>
        ) : null}

        {showPreview ? (
          <section className="min-h-0 overflow-y-auto px-8 py-6" aria-label="Markdown preview">
            <div className="mx-auto max-w-3xl">
              {body.trim() ? (
                <MarkdownPreview content={body} />
              ) : (
                <p className="text-sm text-content-subtle">Nothing to preview yet.</p>
              )}
            </div>
          </section>
        ) : null}
      </div>
    </div>
  );
}
