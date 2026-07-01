import type { AgentExecutionStep, AgentName, AgentThought } from "@/shared/types/chat";

export function upsertTrailStep(
  trail: AgentExecutionStep[],
  step: AgentExecutionStep,
): AgentExecutionStep[] {
  const index = trail.findIndex((item) => item.id === step.id);
  if (index === -1) {
    return [...trail, step];
  }
  const next = [...trail];
  next[index] = step;
  return next;
}

export function mergeExecutionPlan(
  current: AgentExecutionStep[],
  planned: AgentExecutionStep[],
): AgentExecutionStep[] {
  if (current.length === 0) {
    return planned;
  }
  const byId = new Map(current.map((step) => [step.id, step]));
  for (const step of planned) {
    if (!byId.has(step.id)) {
      byId.set(step.id, step);
    }
  }
  const orderedIds = planned.map((step) => step.id);
  for (const step of current) {
    if (!orderedIds.includes(step.id)) {
      orderedIds.push(step.id);
    }
  }
  return orderedIds
    .map((id) => byId.get(id))
    .filter((step): step is AgentExecutionStep => Boolean(step));
}

export function appendAgentThought(
  thoughts: AgentThought[],
  agent: AgentName,
  chunk: string,
): AgentThought[] {
  if (!chunk) {
    return thoughts;
  }
  const last = thoughts[thoughts.length - 1];
  if (last && last.agent === agent) {
    const next = [...thoughts];
    next[next.length - 1] = { agent, text: last.text + chunk };
    return next;
  }
  return [...thoughts, { agent, text: chunk }];
}
