import { ChangePlanCard } from "@/features/ai/components/ChangePlanCard";
import { ChatComposer } from "@/features/ai/components/ChatComposer";
import { ChatMessageList } from "@/features/ai/components/ChatMessageList";
import { useChat } from "@/features/ai/hooks/useChat";
import { useWorkspaceStore } from "@/features/workspace/stores/workspaceStore";

export function ChatPanel() {
  const selectedPath = useWorkspaceStore((s) => s.selectedPath);
  const {
    enabled,
    conversationId,
    messages,
    pendingPlan,
    isLoadingConversation,
    isSending,
    streamingTurn,
    initError,
    sendError,
    sendMessage,
    changeReview,
  } = useChat(selectedPath);

  const handleSend = (content: string) => {
    void sendMessage(content);
  };

  return (
    <aside className="flex h-full w-full flex-col bg-surface-raised">
      <header className="panel-header">
        <h2 className="panel-title">Assistant</h2>
      </header>

      <div className="relative flex min-h-0 flex-1 flex-col">
        {isLoadingConversation && enabled ? (
          <div className="flex flex-1 items-center justify-center text-sm text-content-subtle">
            Starting conversation…
          </div>
        ) : (
          <ChatMessageList messages={messages} streamingTurn={streamingTurn} />
        )}

        {pendingPlan && changeReview.isActive ? (
          <div className="shrink-0 border-t border-border/50 px-4 py-3">
            <ChangePlanCard
              plan={pendingPlan}
              acceptedChangeIds={changeReview.acceptedChangeIds}
              acceptedCount={changeReview.acceptedCount}
              isCommitting={changeReview.isCommitting}
              isRestoring={changeReview.isRestoring}
              error={changeReview.commitError instanceof Error ? changeReview.commitError : null}
              onToggleAccept={changeReview.toggleAccept}
              onAcceptAll={changeReview.acceptAll}
              onRejectAll={changeReview.rejectAll}
              onCommit={() => void changeReview.commitToDisk()}
              onRestore={() => void changeReview.restoreWorkingTree()}
            />
          </div>
        ) : null}

        {initError ? (
          <div className="mx-4 mb-2 rounded-xl border border-red-500/20 bg-red-500/10 px-3 py-2 text-xs text-red-400">
            {initError}
          </div>
        ) : null}

        {sendError && !streamingTurn ? (
          <div className="mx-4 mb-2 rounded-xl border border-red-500/20 bg-red-500/10 px-3 py-2 text-xs text-red-400">
            {sendError}
          </div>
        ) : null}

        <ChatComposer
          disabled={!enabled || !conversationId || isLoadingConversation}
          isSending={isSending}
          onSend={handleSend}
        />
      </div>
    </aside>
  );
}
