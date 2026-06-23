import { EditorContent, useEditor } from "@tiptap/react";
import { useEffect, useRef } from "react";

import { createEditorExtensions } from "@/features/editor/lib/tiptapExtensions";
import { cn } from "@/shared/utils/cn";

interface TiptapEditorProps {
  content: string;
  editable?: boolean;
  onChange: (markdown: string) => void;
  className?: string;
}

export function TiptapEditor({ content, editable = true, onChange, className }: TiptapEditorProps) {
  const suppressOnChange = useRef(false);

  const editor = useEditor({
    extensions: createEditorExtensions(),
    content,
    editable,
    contentType: "markdown",
    immediatelyRender: false,
    editorProps: {
      attributes: {
        class: "tiptap-editor focus:outline-none",
        spellcheck: "true",
      },
    },
    onUpdate: ({ editor: current }) => {
      if (suppressOnChange.current) {
        return;
      }
      onChange(current.getMarkdown());
    },
  });

  useEffect(() => {
    if (!editor) {
      return;
    }
    const currentMarkdown = editor.getMarkdown();
    if (content !== currentMarkdown) {
      suppressOnChange.current = true;
      editor.commands.setContent(content, { contentType: "markdown", emitUpdate: false });
      suppressOnChange.current = false;
    }
  }, [content, editor]);

  useEffect(() => {
    if (editor) {
      editor.setEditable(editable);
    }
  }, [editor, editable]);

  if (!editor) {
    return (
      <div className={cn("flex h-full items-center justify-center text-sm text-content-muted", className)}>
        Loading editor…
      </div>
    );
  }

  return (
    <div className={cn("h-full overflow-y-auto px-8 py-6", className)}>
      <div className="mx-auto max-w-3xl">
        <EditorContent editor={editor} className="min-h-full" />
      </div>
    </div>
  );
}
