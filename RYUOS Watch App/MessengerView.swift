import SwiftUI

private enum ChatPalette {
    static let blue = Color(red: 28 / 255, green: 176 / 255, blue: 246 / 255)
    static let navy = Color(red: 7 / 255, green: 24 / 255, blue: 43 / 255)
}

struct MessengerView: View {
    @State private var store = MessengerStore()

    var body: some View {
        List {
            Section {
                ForEach(store.conversations) { chat in
                    NavigationLink {
                        ChatDetailView(store: store, conversationID: chat.id)
                    } label: {
                        ConversationRow(chat: chat)
                    }
                    .listRowBackground(ChatPalette.navy)
                }
            } header: {
                Text("Demo chats")
            } footer: {
                Text("Offline demo. Replies stay on this Watch.")
            }

            if !store.isLoaded {
                Button("Load chats") { store.load() }
            }
        }
        .scrollContentBackground(.hidden)
        .background(ChatPalette.navy)
        .navigationTitle("Messenger")
        .toolbar(.visible, for: .navigationBar)
        .fontDesign(.rounded)
        .tint(ChatPalette.blue)
        .task { store.load() }
        .alert("Messenger", isPresented: Binding(
            get: { store.errorMessage != nil },
            set: { if !$0 { store.errorMessage = nil } }
        )) {
            Button("OK") { store.errorMessage = nil }
        } message: {
            Text(store.errorMessage ?? "")
        }
    }
}

private struct ConversationRow: View {
    let chat: ChatConversation

    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            Image(systemName: chat.symbol)
                .font(.headline)
                .foregroundStyle(ChatPalette.blue)
                .frame(width: 28, height: 32)
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 3) {
                HStack {
                    Text(chat.name)
                        .font(.headline)
                        .lineLimit(1)
                    Spacer(minLength: 0)
                    if chat.unreadCount > 0 {
                        Text("\(chat.unreadCount)")
                            .font(.caption2.bold())
                            .padding(4)
                            .background(ChatPalette.blue, in: Circle())
                            .foregroundStyle(ChatPalette.navy)
                            .accessibilityLabel("\(chat.unreadCount) unread")
                    }
                }
                Text(chat.draft.isEmpty ? (chat.messages.last?.text ?? "No messages") : "Draft: \(chat.draft)")
                    .font(.caption)
                    .foregroundStyle(chat.draft.isEmpty ? .white.opacity(0.75) : ChatPalette.blue)
                    .lineLimit(2)
                if let date = chat.messages.last?.createdAt {
                    Text(date, style: .time)
                        .font(.caption2)
                        .foregroundStyle(.white.opacity(0.6))
                }
            }
        }
        .padding(.vertical, 4)
    }
}

private struct ChatDetailView: View {
    let store: MessengerStore
    let conversationID: String
    @State private var isComposing = false

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView {
                VStack(spacing: 10) {
                    Text("Demo · replies saved locally")
                        .font(.caption2)
                        .foregroundStyle(.white.opacity(0.7))
                    if let chat = store.conversation(conversationID) {
                        ForEach(chat.messages) { message in
                            MessageBubble(message: message)
                        }
                        Button {
                            isComposing = true
                        } label: {
                            Label(chat.draft.isEmpty ? "Reply" : "Edit Draft", systemImage: "square.and.pencil")
                                .frame(maxWidth: .infinity, minHeight: 36)
                        }
                        .modifier(ChatPrimaryControl())
                        .id("reply")
                    }
                }
                .padding(.horizontal, 8)
                .padding(.bottom)
            }
            .background(ChatPalette.navy)
            .onAppear {
                store.markRead(conversationID)
                proxy.scrollTo("reply", anchor: .bottom)
            }
            .onChange(of: store.conversation(conversationID)?.messages.count) {
                proxy.scrollTo("reply", anchor: .bottom)
            }
        }
        .navigationTitle(store.conversation(conversationID)?.name ?? "Chat")
        .sheet(isPresented: $isComposing) {
            ComposeMessageView(store: store, conversationID: conversationID)
        }
    }
}

private struct MessageBubble: View {
    let message: ChatMessage
    private var isOutgoing: Bool { message.status != .received }

    var body: some View {
        VStack(alignment: isOutgoing ? .trailing : .leading, spacing: 4) {
            Text(message.text)
                .font(.body)
                .padding(10)
                .foregroundStyle(isOutgoing ? ChatPalette.navy : .white)
                .background(isOutgoing ? ChatPalette.blue : .white.opacity(0.12),
                            in: RoundedRectangle(cornerRadius: 14))
            HStack(spacing: 4) {
                if isOutgoing {
                    Text(message.status == .queued ? "Queued · offline" : "Sent")
                }
                Text(message.createdAt, style: .time)
            }
            .font(.caption2)
            .foregroundStyle(.white.opacity(0.75))
        }
        .frame(maxWidth: .infinity, alignment: isOutgoing ? .trailing : .leading)
        .padding(isOutgoing ? .leading : .trailing, 12)
        .accessibilityElement(children: .combine)
    }
}

private struct ComposeMessageView: View {
    @Environment(\.dismiss) private var dismiss
    let store: MessengerStore
    let conversationID: String
    @State private var showQuickReplies = false
    @State private var showEmoji = false

    private var draft: String { store.conversation(conversationID)?.draft ?? "" }
    private var canQueue: Bool {
        !draft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && draft.count <= 1000
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 10) {
                    TextField("Message", text: Binding(
                        get: { draft },
                        set: { store.saveDraft($0, in: conversationID) }
                    ))
                    .accessibilityHint("Use the Watch keyboard, Scribble, or dictation when available.")

                    if !draft.isEmpty {
                        Text(draft)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .font(.body)
                    }

                    Button("Quick Replies", systemImage: "text.bubble") {
                        showQuickReplies = true
                    }
                    .buttonStyle(.bordered)
                    Button("Emoji", systemImage: "face.smiling") {
                        showEmoji = true
                    }
                    .buttonStyle(.bordered)

                    Text("\(draft.count)/1000 · Draft saved")
                        .font(.caption2)
                        .foregroundStyle(draft.count > 1000 ? .white : .white.opacity(0.7))

                    Button {
                        if store.queueDraft(in: conversationID) { dismiss() }
                    } label: {
                        Label("Queue Reply", systemImage: "paperplane.fill")
                            .frame(maxWidth: .infinity, minHeight: 36)
                    }
                    .modifier(ChatPrimaryControl())
                    .disabled(!canQueue)

                    Text("Saved on this Watch. Not sent to anyone.")
                        .font(.caption2)
                        .multilineTextAlignment(.center)
                        .foregroundStyle(.white.opacity(0.75))
                }
                .padding(.horizontal, 8)
                .padding(.bottom)
            }
            .background(ChatPalette.navy)
            .navigationTitle("Reply")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                }
            }
            .sheet(isPresented: $showQuickReplies) {
                ReplyPicker(title: "Quick Replies", choices: ["On my way!", "Thanks!", "Talk soon.", "Yes", "No", "I'll reply later."]) {
                    store.saveDraft($0, in: conversationID)
                }
            }
            .sheet(isPresented: $showEmoji) {
                ReplyPicker(title: "Emoji", choices: ["👍", "💙", "😊", "🙏", "🎉", "👋"]) {
                    store.saveDraft(draft + $0, in: conversationID)
                }
            }
        }
        .tint(ChatPalette.blue)
        .fontDesign(.rounded)
    }
}

private struct ReplyPicker: View {
    @Environment(\.dismiss) private var dismiss
    let title: LocalizedStringKey
    let choices: [String]
    let select: (String) -> Void

    var body: some View {
        NavigationStack {
            List(choices, id: \.self) { choice in
                Button(choice) {
                    select(choice)
                    dismiss()
                }
            }
            .navigationTitle(title)
        }
    }
}

private struct ChatPrimaryControl: ViewModifier {
    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency

    func body(content: Content) -> some View {
        Group {
            if reduceTransparency {
                content.buttonStyle(.borderedProminent)
            } else {
                content.buttonStyle(.glassProminent)
            }
        }
        .tint(ChatPalette.blue)
        .foregroundStyle(ChatPalette.navy)
    }
}
