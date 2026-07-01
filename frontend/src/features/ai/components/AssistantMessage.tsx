import { MarkdownPreview } from "@/features/editor/components/MarkdownPreview";
import { normalizeMarkdownText } from "@/features/editor/lib/normalizeMarkdown";
import { cn } from "@/shared/utils/cn";

interface AssistantMessageProps {
  content: string;
  isStreaming?: boolean;
  className?: string;
}

export function AssistantMessage({
  content,
  isStreaming = false,
  className,
}: AssistantMessageProps) {
  if (!content && isStreaming) {
    return (
      <span className="inline-flex items-center gap-1 text-content-subtle">
        <span className="h-1.5 w-1.5 animate-pulse rounded-full bg-content-subtle" />
        <span className="h-1.5 w-1.5 animate-pulse rounded-full bg-content-subtle [animation-delay:150ms]" />
        <span className="h-1.5 w-1.5 animate-pulse rounded-full bg-content-subtle [animation-delay:300ms]" />
      </span>
    );
  }

  const markdown = normalizeMarkdownText(content);

  return (
    <div className={cn("prose-chat text-sm leading-relaxed text-content", className)}>
      <MarkdownPreview content={markdown} />
      {isStreaming ? (
        <span className="ml-0.5 inline-block h-4 w-0.5 animate-pulse bg-content-muted align-middle" />
      ) : null}
    </div>
  );
}
