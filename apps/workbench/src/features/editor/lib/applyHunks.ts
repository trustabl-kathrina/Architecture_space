import type { ChangePlan, ChangePlanHunk, SectionChange } from "@/shared/types/chat";

const INTRO_PATH = "__intro__";

interface ParsedSection {
  title: string;
  level: number;
  path: string;
  lines: string[];
  startLine: number;
}

const HEADING_RE = /^(#{1,6})\s+(.+)$/;

function parseSections(body: string): ParsedSection[] {
  const lines = body.split("\n");
  if (lines.length === 0) {
    return [];
  }

  const sections: ParsedSection[] = [];
  const pathStack: Array<{ level: number; title: string }> = [];
  let currentLines: string[] = [];
  let currentTitle = "(Introduction)";
  let currentLevel = 0;
  let currentPath = INTRO_PATH;
  let currentStart = 1;

  const flush = () => {
    if (!currentLines.length && currentPath !== INTRO_PATH) {
      return;
    }
    sections.push({
      title: currentTitle,
      level: currentLevel,
      path: currentPath,
      lines: [...currentLines],
      startLine: currentStart,
    });
  };

  for (let index = 0; index < lines.length; index += 1) {
    const line = lines[index];
    const lineNumber = index + 1;
    const match = line.match(HEADING_RE);
    if (match) {
      if (currentLines.length || currentPath !== INTRO_PATH || lineNumber === 1) {
        flush();
      }
      const level = match[1].length;
      const title = match[2].trim();
      while (pathStack.length > 0 && pathStack[pathStack.length - 1].level >= level) {
        pathStack.pop();
      }
      pathStack.push({ level, title });
      currentPath = pathStack.map((entry) => entry.title).join("/");
      currentTitle = title;
      currentLevel = level;
      currentStart = lineNumber;
      currentLines = [line];
      continue;
    }
    if (!currentLines.length && currentPath === INTRO_PATH) {
      currentStart = lineNumber;
    }
    currentLines.push(line);
  }

  flush();
  return sections;
}

function sectionText(section: ParsedSection): string {
  return section.lines.join("\n").trim();
}

function orderedPaths(original: string, proposed: string): string[] {
  const seen = new Set<string>();
  const ordered: string[] = [];
  for (const section of [...parseSections(proposed), ...parseSections(original)]) {
    if (!seen.has(section.path)) {
      ordered.push(section.path);
      seen.add(section.path);
    }
  }
  return ordered;
}

export function applySectionChanges(
  original: string,
  proposed: string,
  sections: SectionChange[],
  acceptedIds: Set<string>,
): string {
  if (!sections.length) {
    return acceptedIds.size > 0 ? proposed : original;
  }
  if (!acceptedIds.size) {
    return original;
  }
  if (acceptedIds.size === sections.length) {
    return proposed;
  }

  const origMap = new Map(parseSections(original).map((section) => [section.path, section]));
  const propMap = new Map(parseSections(proposed).map((section) => [section.path, section]));
  const changeByPath = new Map(sections.map((section) => [section.sectionPath, section]));
  const output: string[] = [];

  for (const path of orderedPaths(original, proposed)) {
    const change = changeByPath.get(path);
    const origSection = origMap.get(path);
    const propSection = propMap.get(path);

    if (!change) {
      const section = propSection ?? origSection;
      if (section?.lines.length) {
        output.push(section.lines.join("\n"));
      }
      continue;
    }

    if (!acceptedIds.has(change.id)) {
      if (origSection?.lines.length) {
        output.push(origSection.lines.join("\n"));
      }
      continue;
    }

    if (change.changeType === "deleted") {
      continue;
    }

    if (propSection?.lines.length) {
      output.push(propSection.lines.join("\n"));
    }
  }

  const merged = output.filter((part) => part.trim()).join("\n\n").trim();
  return merged ? `${merged}\n` : "";
}

/** Apply accepted line hunks (legacy fallback). */
export function applyHunks(
  original: string,
  hunks: ChangePlanHunk[],
  acceptedIds: Set<string>,
): string {
  if (acceptedIds.size === 0) {
    return original;
  }

  const lines = original.split("\n");
  const selected = hunks.filter((hunk) => acceptedIds.has(hunk.id));

  for (const hunk of [...selected].sort((a, b) => b.startLine - a.startLine)) {
    const startIdx = Math.max(hunk.startLine - 1, 0);
    const endIdx = hunk.endLine > startIdx ? hunk.endLine : startIdx;
    const proposedLines = hunk.proposed.split("\n");

    if (hunk.type === "insert") {
      lines.splice(startIdx, 0, ...proposedLines);
    } else if (hunk.type === "delete") {
      lines.splice(startIdx, endIdx - startIdx);
    } else {
      lines.splice(startIdx, endIdx - startIdx, ...proposedLines);
    }
  }

  return lines.join("\n");
}

export function planChangeUnits(plan: ChangePlan): Array<SectionChange | ChangePlanHunk> {
  if (plan.hunks.length > 0) {
    return plan.hunks;
  }
  return plan.sections;
}

export function resolvePreviewBody(
  originalBody: string,
  plan: ChangePlan,
  acceptedIds: Set<string>,
): string {
  if (acceptedIds.size === 0) {
    return originalBody;
  }

  if (plan.hunks.length > 0) {
    if (acceptedIds.size === plan.hunks.length) {
      return plan.proposedBody;
    }
    return applyHunks(originalBody, plan.hunks, acceptedIds);
  }

  if (plan.sections.length > 0) {
    return applySectionChanges(originalBody, plan.proposedBody, plan.sections, acceptedIds);
  }

  if (acceptedIds.size === 0) {
    return originalBody;
  }

  return plan.proposedBody;
}

export function buildDiffLines(original: string, proposed: string): DiffLine[] {
  const a = original.split("\n");
  const b = proposed.split("\n");
  const result: DiffLine[] = [];

  let i = 0;
  let j = 0;

  while (i < a.length || j < b.length) {
    if (i < a.length && j < b.length && a[i] === b[j]) {
      result.push({ type: "context", text: a[i], oldLine: i + 1, newLine: j + 1 });
      i += 1;
      j += 1;
      continue;
    }

    const nextMatchInB = j < b.length ? a.indexOf(b[j], i) : -1;
    const nextMatchInA = i < a.length ? b.indexOf(a[i], j) : -1;

    if (nextMatchInB !== -1 && (nextMatchInA === -1 || nextMatchInB - i <= nextMatchInA - j)) {
      while (i < nextMatchInB) {
        result.push({ type: "remove", text: a[i], oldLine: i + 1, newLine: null });
        i += 1;
      }
    } else if (nextMatchInA !== -1) {
      while (j < nextMatchInA) {
        result.push({ type: "add", text: b[j], oldLine: null, newLine: j + 1 });
        j += 1;
      }
    } else if (i < a.length && j < b.length) {
      result.push({ type: "remove", text: a[i], oldLine: i + 1, newLine: null });
      result.push({ type: "add", text: b[j], oldLine: null, newLine: j + 1 });
      i += 1;
      j += 1;
    } else if (i < a.length) {
      result.push({ type: "remove", text: a[i], oldLine: i + 1, newLine: null });
      i += 1;
    } else {
      result.push({ type: "add", text: b[j], oldLine: null, newLine: j + 1 });
      j += 1;
    }
  }

  return result;
}

export interface DiffLine {
  type: "context" | "add" | "remove";
  text: string;
  oldLine: number | null;
  newLine: number | null;
}

export function sectionChangeLabel(section: SectionChange): string {
  if (section.changeType === "new") {
    return `+ New section: ${section.sectionTitle}`;
  }
  if (section.changeType === "deleted") {
    return `- Remove section: ${section.sectionTitle}`;
  }
  return `~ Update section: ${section.sectionTitle}`;
}
