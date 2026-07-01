import { useEffect, useMemo, useRef } from "react";
import mermaid from "mermaid";

import { renderMarkdownToHtml } from "@/features/editor/lib/markdown";
import { cn } from "@/shared/utils/cn";

let mermaidInitialized = false;

function ensureMermaid() {
  if (!mermaidInitialized) {
    mermaid.initialize({
      startOnLoad: false,
      theme: "dark",
      securityLevel: "strict",
    });
    mermaidInitialized = true;
  }
}

interface MarkdownPreviewProps {
  content: string;
  className?: string;
}

export function MarkdownPreview({ content, className }: MarkdownPreviewProps) {
  const containerRef = useRef<HTMLDivElement>(null);
  const html = useMemo(() => renderMarkdownToHtml(content), [content]);

  useEffect(() => {
    ensureMermaid();
    const container = containerRef.current;
    if (!container) {
      return;
    }

    const blocks = container.querySelectorAll<HTMLElement>("pre.mermaid");
    if (blocks.length === 0) {
      return;
    }

    void mermaid
      .run({ nodes: Array.from(blocks) })
      .catch((error: unknown) => {
        console.error("Mermaid render failed", error);
      });
  }, [html]);

  return (
    <div
      ref={containerRef}
      className={cn("markdown-preview", className)}
      dangerouslySetInnerHTML={{ __html: html }}
    />
  );
}
