import { DocTree } from "@/features/workspace/components/DocTree";
import { useDocTree } from "@/features/workspace/hooks/useDocTree";

export function Sidebar() {
  const { createFolder, createDocument, refreshTree, isFetching } = useDocTree();

  return (
    <aside className="flex h-full w-full flex-col bg-surface-raised">
      <header className="panel-header justify-between gap-2">
        <h2 className="panel-title">Documents</h2>
        <button
          type="button"
          className="btn-secondary px-2 py-1 text-[10px]"
          title="Refresh tree from disk"
          disabled={isFetching}
          onClick={() => void refreshTree()}
        >
          {isFetching ? "Syncing…" : "Sync"}
        </button>
      </header>

      <div className="min-h-0 flex-1">
        <DocTree />
      </div>

      <footer className="flex shrink-0 gap-1.5 border-t border-border/50 p-3">
        <button
          type="button"
          className="btn-secondary flex-1 text-xs"
          onClick={() => {
            const name = window.prompt("New folder name:");
            if (name?.trim()) {
              void createFolder({ parentPath: "", name: name.trim() });
            }
          }}
        >
          New folder
        </button>
        <button
          type="button"
          className="btn-secondary flex-1 text-xs"
          onClick={() => {
            const name = window.prompt("New document name:");
            if (name?.trim()) {
              void createDocument({ parentPath: "", name: name.trim() });
            }
          }}
        >
          New doc
        </button>
      </footer>
    </aside>
  );
}
