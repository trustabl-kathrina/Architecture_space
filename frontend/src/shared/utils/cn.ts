/**
 * Merge class names, skipping falsy values.
 * Tailwind-aware merging can be added later via tailwind-merge.
 */
export function cn(...classes: Array<string | false | null | undefined>): string {
  return classes.filter(Boolean).join(" ");
}
