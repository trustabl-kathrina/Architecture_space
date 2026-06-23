import { parseFrontMatterFields } from "@/features/editor/lib/frontMatter";
import { cn } from "@/shared/utils/cn";

interface DocumentMetaBarProps {
  frontMatter: string | null;
  body: string;
  className?: string;
}

export function DocumentMetaBar({ frontMatter, body, className }: DocumentMetaBarProps) {
  const fields = parseFrontMatterFields(frontMatter);
  const isEmptyBody = body.trim().length === 0;

  if (!fields && !isEmptyBody) {
    return null;
  }

  return (
    <div
      className={cn(
        "border-b border-border/50 bg-surface-overlay/30 px-8 py-3 text-xs text-content-muted",
        className,
      )}
    >
      {fields ? (
        <dl className="mx-auto flex max-w-3xl flex-wrap gap-x-4 gap-y-1">
          {fields.title ? (
            <div className="flex gap-1.5">
              <dt className="text-content-subtle">Title</dt>
              <dd className="text-content">{fields.title}</dd>
            </div>
          ) : null}
          {fields.status ? (
            <div className="flex gap-1.5">
              <dt className="text-content-subtle">Status</dt>
              <dd className="text-content">{fields.status}</dd>
            </div>
          ) : null}
          {fields.template ? (
            <div className="flex gap-1.5">
              <dt className="text-content-subtle">Template</dt>
              <dd className="text-content">{fields.template}</dd>
            </div>
          ) : null}
          {fields.section ? (
            <div className="flex gap-1.5">
              <dt className="text-content-subtle">Section</dt>
              <dd className="text-content">{fields.section}</dd>
            </div>
          ) : null}
        </dl>
      ) : null}

      {isEmptyBody ? (
        <p className="mx-auto mt-2 max-w-3xl text-content-subtle">
          This document has no body content yet
          {fields?.status === "stub" ? " (stub — ready for drafting)" : ""}.
          Use the assistant to draft a section or start writing in the editor.
        </p>
      ) : null}
    </div>
  );
}
