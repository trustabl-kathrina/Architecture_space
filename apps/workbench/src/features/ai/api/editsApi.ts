import { mapChangePlan } from "@/features/ai/api/chatMappers";
import { env } from "@/shared/config/env";
import { apiRequest } from "@/shared/api/client";
import type { ApplyChangePlanRequest, ApplyChangePlanResponse, ChangePlan } from "@/shared/types/chat";

const BASE = env.apiBaseUrl;

export const editKeys = {
  all: ["edits"] as const,
  detail: (editId: string) => [...editKeys.all, editId] as const,
};

export async function fetchChangePlan(editId: string): Promise<ChangePlan> {
  const raw = await apiRequest<Record<string, unknown>>(BASE, `/edits/${editId}`);
  return mapChangePlan(raw);
}

export async function applyChangePlan(
  editId: string,
  request: ApplyChangePlanRequest = {},
): Promise<ApplyChangePlanResponse> {
  const raw = await apiRequest<Record<string, unknown>>(BASE, `/edits/${editId}/apply`, {
    method: "POST",
    body: {
      accepted_hunk_ids: request.acceptedHunkIds ?? null,
    },
  });
  return {
    editId: String(raw.edit_id),
    documentPath: String(raw.document_path),
    checksum: String(raw.checksum),
    applied: Boolean(raw.applied),
    diskPath: raw.disk_path ? String(raw.disk_path) : null,
  };
}

export async function discardChangePlan(editId: string): Promise<ChangePlan> {
  const raw = await apiRequest<Record<string, unknown>>(BASE, `/edits/${editId}`, {
    method: "DELETE",
  });
  return mapChangePlan(raw);
}
