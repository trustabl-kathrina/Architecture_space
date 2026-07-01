import type { FolderPlanResult } from "@/shared/types/chat";

/** Text for the folder planning panel textarea (mirrors API compose_plan_textarea). */
export function composePlanTextarea(result: FolderPlanResult): string {
  const lines = [
    "# Target structure",
    "",
    result.targetStructure.trim(),
    "",
    "# Reorganization",
    "",
  ];
  for (const item of result.reorganization) {
    const target = item.targetPath ? ` -> ${item.targetPath}` : "";
    lines.push(`- [${item.action}] ${item.path}${target}: ${item.rationale}`);
  }
  lines.push("", "# Notes", "", result.explanation.trim());
  return `${lines.join("\n").trim()}\n`;
}

const AI_REVISION_SPLIT = /\n---\n\n# AI revision\n\n/;

/** Merge AI output into the user's draft without discarding manual edits. */
export function mergeAiPlanIntoDraft(
  currentPlan: string,
  lastAiPlan: string,
  newAiPlan: string,
): { merged: string; lastAiPlan: string } {
  const trimmedCurrent = currentPlan.trim();
  const trimmedLastAi = lastAiPlan.trim();

  if (!trimmedCurrent || trimmedCurrent === trimmedLastAi) {
    return { merged: newAiPlan, lastAiPlan: newAiPlan };
  }

  const userBase = trimmedCurrent.split(AI_REVISION_SPLIT)[0]?.trim() ?? trimmedCurrent;
  const hasAiRevisionBlock = AI_REVISION_SPLIT.test(trimmedCurrent);

  if (!hasAiRevisionBlock && trimmedCurrent !== trimmedLastAi) {
    return { merged: newAiPlan, lastAiPlan: newAiPlan };
  }

  if (userBase && userBase !== trimmedLastAi) {
    return { merged: newAiPlan, lastAiPlan: newAiPlan };
  }

  return {
    merged: `${userBase}\n\n---\n\n# AI revision\n\n${newAiPlan}`,
    lastAiPlan: newAiPlan,
  };
}
