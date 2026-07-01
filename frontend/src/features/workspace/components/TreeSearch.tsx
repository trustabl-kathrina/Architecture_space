import { useWorkspaceStore } from "@/features/workspace/stores/workspaceStore";

export function TreeSearch() {
  const treeFilter = useWorkspaceStore((s) => s.treeFilter);
  const setTreeFilter = useWorkspaceStore((s) => s.setTreeFilter);

  return (
    <div className="px-3 py-2.5">
      <input
        type="search"
        value={treeFilter}
        onChange={(event) => setTreeFilter(event.target.value)}
        placeholder="Search documents…"
        className="input-field"
        aria-label="Search documentation tree"
      />
    </div>
  );
}
