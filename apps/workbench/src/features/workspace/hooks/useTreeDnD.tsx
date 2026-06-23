import {
  DndContext,
  type DragEndEvent,
  DragOverlay,
  type DragStartEvent,
  PointerSensor,
  useDraggable,
  useDroppable,
  useSensor,
  useSensors,
} from "@dnd-kit/core";
import { CSS } from "@dnd-kit/utilities";
import { useState, type ReactNode } from "react";

import type { TreeNode } from "@/shared/types/workspace";

export function useTreeDnD(onMove: (path: string, newParentPath: string) => Promise<void>) {
  const [activeNode, setActiveNode] = useState<TreeNode | null>(null);
  const sensors = useSensors(
    useSensor(PointerSensor, {
      activationConstraint: { distance: 6 },
    }),
  );

  const handleDragStart = (event: DragStartEvent) => {
    setActiveNode(event.active.data.current?.node as TreeNode);
  };

  const handleDragEnd = async (event: DragEndEvent) => {
    setActiveNode(null);
    const source = event.active.data.current?.node as TreeNode | undefined;
    const target = event.over?.data.current?.node as TreeNode | undefined;
    if (!source || !target || target.type !== "folder") {
      return;
    }
    const currentParent = source.path.includes("/")
      ? source.path.slice(0, source.path.lastIndexOf("/"))
      : "";
    if (currentParent === target.path) {
      return;
    }
    if (source.type === "folder" && target.path.startsWith(`${source.path}/`)) {
      return;
    }
    await onMove(source.path, target.path);
  };

  return { sensors, activeNode, handleDragStart, handleDragEnd };
}

export function TreeDndProvider({
  children,
  onMove,
}: {
  children: ReactNode;
  onMove: (path: string, newParentPath: string) => Promise<void>;
}) {
  const { sensors, activeNode, handleDragStart, handleDragEnd } = useTreeDnD(onMove);

  return (
    <DndContext sensors={sensors} onDragStart={handleDragStart} onDragEnd={handleDragEnd}>
      {children}
      <DragOverlay>
        {activeNode ? (
          <div className="rounded-md border border-accent bg-surface-raised px-2 py-1 text-sm shadow-lg">
            {activeNode.name}
          </div>
        ) : null}
      </DragOverlay>
    </DndContext>
  );
}

export function useDraggableNode(node: TreeNode, disabled = false) {
  const { attributes, listeners, setNodeRef, transform, isDragging } = useDraggable({
    id: `drag-${node.path}`,
    data: { node },
    disabled,
  });

  const style = transform ? { transform: CSS.Translate.toString(transform) } : undefined;

  return { attributes, listeners, setNodeRef, style, isDragging };
}

export function useDroppableFolder(node: TreeNode) {
  const { isOver, setNodeRef } = useDroppable({
    id: `drop-${node.path}`,
    data: { node },
    disabled: node.type !== "folder",
  });

  return { isOver, setNodeRef };
}
