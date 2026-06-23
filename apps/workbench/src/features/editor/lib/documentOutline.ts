/** Extract markdown headings from document body for chat context. */

const HEADING_RE = /^(#{1,6})\s+(.+)$/gm;

export function extractDocumentOutline(body: string): string[] {
  const headings: string[] = [];
  let match: RegExpExecArray | null;
  const re = new RegExp(HEADING_RE.source, HEADING_RE.flags);
  while ((match = re.exec(body)) !== null) {
    const level = match[1].length;
    const indent = "  ".repeat(Math.max(0, level - 1));
    headings.push(`${indent}${match[2].trim()}`);
  }
  return headings;
}

/** Pick the most relevant section heading for the active document. */
export function inferActiveSection(body: string, userMessage: string): string | null {
  const outline = extractDocumentOutline(body);
  if (outline.length === 0) {
    return null;
  }

  const loweredMessage = userMessage.toLowerCase();
  const direct = outline.find((heading) => loweredMessage.includes(heading.trim().toLowerCase()));
  if (direct) {
    return direct.trim();
  }

  return outline[0]?.trim() ?? null;
}
