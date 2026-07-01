const FRONT_MATTER_PATTERN = /^---\r?\n([\s\S]*?)\r?\n---\r?\n?/;

export interface SplitDocument {
  frontMatter: string | null;
  body: string;
}

export interface FrontMatterFields {
  title?: string;
  status?: string;
  template?: string;
  section?: string;
}

/** Parse common YAML front matter keys for display (no external YAML dependency). */
export function parseFrontMatterFields(frontMatter: string | null): FrontMatterFields | null {
  if (!frontMatter) {
    return null;
  }

  const inner = frontMatter.replace(/^---\r?\n?/, "").replace(/\r?\n?---\r?\n?$/, "");
  const fields: FrontMatterFields = {};

  for (const line of inner.split(/\r?\n/)) {
    const match = line.match(/^([A-Za-z0-9_]+):\s*(.+?)\s*$/);
    if (!match) {
      continue;
    }
    const key = match[1].toLowerCase();
    let value = match[2].trim();
    if (
      (value.startsWith('"') && value.endsWith('"')) ||
      (value.startsWith("'") && value.endsWith("'"))
    ) {
      value = value.slice(1, -1);
    }
    if (key === "title") {
      fields.title = value;
    } else if (key === "status") {
      fields.status = value;
    } else if (key === "template") {
      fields.template = value;
    } else if (key === "section") {
      fields.section = value;
    }
  }

  return Object.keys(fields).length > 0 ? fields : null;
}

/** Split YAML front matter from Markdown body. */
export function splitFrontMatter(content: string): SplitDocument {
  const match = content.match(FRONT_MATTER_PATTERN);
  if (!match) {
    return { frontMatter: null, body: content };
  }
  return {
    frontMatter: `---\n${match[1]}\n---\n`,
    body: content.slice(match[0].length),
  };
}

/** Rejoin front matter and edited body for persistence. */
export function joinFrontMatter(frontMatter: string | null, body: string): string {
  if (!frontMatter) {
    return body;
  }
  return `${frontMatter}${body.startsWith("\n") ? "" : "\n"}${body}`;
}
