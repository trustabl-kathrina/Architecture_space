import { ChangePlanCard } from "@/features/ai/components/ChangePlanCard";
import { ChatComposer } from "@/features/ai/components/ChatComposer";
import { ChatMessageList } from "@/features/ai/components/ChatMessageList";
import { ChatModeToggle } from "@/features/ai/components/ChatModeToggle";
import { useChat } from "@/features/ai/hooks/useChat";
import { useChatStore } from "@/features/ai/stores/chatStore";
import { useWorkspaceStore } from "@/features/workspace/stores/workspaceStore";

export function ChatPanel() {
  const activeTab = useWorkspaceStore((s) => s.activeTab);
  const chatMode = useChatStore((s) => s.chatMode);
  const setChatMode = useChatStore((s) => s.setChatMode);
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
    editMessageAndRegenerate,
    deleteMessageAndAfter,
    clearChat,
    changeReview,
  } = useChat(activeTab);

  const handleSend = (content: string) => {
    void sendMessage(content);
  };

  return (
    <aside className="flex h-full w-full flex-col bg-surface-raised">
      <header className="panel-header justify-between gap-3">
        <h2 className="panel-title">Assistant</h2>
        <div className="flex items-center gap-2">
          {messages.length > 0 ? (
            <button
              type="button"
              onClick={() => void clearChat()}
              disabled={!conversationId || isSending}
              className="rounded-lg px-2 py-1 text-[11px] text-content-subtle hover:bg-surface-overlay hover:text-content disabled:opacity-40"
              title="Clear chat history for this section"
            >
              Clear chat
            </button>
          ) : null}
          <ChatModeToggle
            mode={chatMode}
            onChange={setChatMode}
            disabled={!enabled || isSending}
          />
        </div>
      </header>

      <div className="relative flex min-h-0 flex-1 flex-col">
        {isLoadingConversation && enabled ? (
          <div className="flex flex-1 items-center justify-center text-sm text-content-subtle">
            Starting conversation…
          </div>
        ) : (
          <ChatMessageList
            messages={messages}
            streamingTurn={streamingTurn}
            isSending={isSending}
            onEditMessage={(messageId, content) => void editMessageAndRegenerate(messageId, content)}
            onDeleteMessage={(messageId) => void deleteMessageAndAfter(messageId)}
          />
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
          chatMode={chatMode}
          activeTabKind={activeTab?.kind ?? null}
          onSend={handleSend}
        />
      </div>
    </aside>
  );
}
