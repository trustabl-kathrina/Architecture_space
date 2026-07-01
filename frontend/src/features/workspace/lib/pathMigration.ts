/** Map legacy multi-segment prefixes to 2-digit local folder/file names. */

const LONG_PREFIX_RE = /^(\d{2}(?:\.\d{2})+)_(.+)$/;

export function shortenPathSegment(name: string): string {
  const match = name.match(LONG_PREFIX_RE);
  if (!match) {
    return name;
  }
  const local = match[1].split(".").pop() ?? match[1];
  return `${local}_${match[2]}`;
}

export function remapLegacyPath(path: string): string {
  return path
    .split("/")
    .filter(Boolean)
    .map(shortenPathSegment)
    .join("/");
}

/** Repeat shortening until stable (handles partially migrated persisted paths). */
export function normalizeWorkspacePath(path: string): string {
  let current = path.trim();
  for (let attempt = 0; attempt < 8; attempt += 1) {
    const next = remapLegacyPath(current);
    if (next === current) {
      return current;
    }
    current = next;
  }
  return current;
}

export function normalizeWorkspacePaths(paths: string[]): string[] {
  const seen = new Set<string>();
  const result: string[] = [];
  for (const path of paths) {
    const normalized = normalizeWorkspacePath(path);
    if (normalized && !seen.has(normalized)) {
      seen.add(normalized);
      result.push(normalized);
    }
  }
  return result;
}
