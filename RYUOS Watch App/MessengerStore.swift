import Foundation
import Observation

struct ChatMessage: Codable, Identifiable, Sendable {
    enum Status: String, Codable, Sendable {
        case received, queued, sent
    }

    let id: UUID
    let text: String
    let createdAt: Date
    var status: Status
}

struct ChatConversation: Codable, Identifiable, Sendable {
    let id: String
    let name: String
    let symbol: String
    var unreadCount: Int
    var messages: [ChatMessage]
    var draft: String

    static var samples: [ChatConversation] {
        [
            ChatConversation(id: "demo-maya", name: "Maya", symbol: "person.fill", unreadCount: 1,
                messages: [ChatMessage(id: UUID(), text: "Want to grab lunch?", createdAt: .now, status: .received)], draft: ""),
            ChatConversation(id: "demo-family", name: "Family", symbol: "person.2.fill", unreadCount: 1,
                messages: [ChatMessage(id: UUID(), text: "Let us know when you arrive 💙", createdAt: .now, status: .received)], draft: ""),
            ChatConversation(id: "demo-study", name: "Study Group", symbol: "character.book.closed.fill", unreadCount: 0,
                messages: [ChatMessage(id: UUID(), text: "Ready to practice Mandarin?", createdAt: .now, status: .received)], draft: "")
        ]
    }
}

@MainActor
@Observable
final class MessengerStore {
    private(set) var conversations: [ChatConversation] = []
    private(set) var isLoaded = false
    var errorMessage: String?
    private let storageKey = "ryuos.messenger.v1"
    private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    func load() {
        guard !isLoaded else { return }
        do {
            if let data = defaults.data(forKey: storageKey) {
                conversations = try JSONDecoder().decode([ChatConversation].self, from: data)
            } else {
                conversations = ChatConversation.samples
            }
            isLoaded = true
        } catch {
            // Do not overwrite unreadable saved data with sample conversations.
            errorMessage = "Saved chats could not be opened. Please try again."
        }
    }

    func conversation(_ id: String) -> ChatConversation? {
        conversations.first { $0.id == id }
    }

    func saveDraft(_ text: String, in id: String) {
        update(id) { $0.draft = text }
    }

    func markRead(_ id: String) {
        guard conversation(id)?.unreadCount != 0 else { return }
        update(id) { $0.unreadCount = 0 }
    }

    @discardableResult
    func queueDraft(in id: String) -> Bool {
        guard let chat = conversation(id) else { return false }
        let text = chat.draft.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty, text.count <= 1000 else { return false }
        return update(id) {
            $0.messages.append(ChatMessage(id: UUID(), text: text, createdAt: .now, status: .queued))
            $0.draft = ""
        }
    }

    @discardableResult
    private func update(_ id: String, change: (inout ChatConversation) -> Void) -> Bool {
        guard let index = conversations.firstIndex(where: { $0.id == id }) else { return false }
        var updated = conversations
        change(&updated[index])
        do {
            let data = try JSONEncoder().encode(updated)
            defaults.set(data, forKey: storageKey)
            conversations = updated
            return true
        } catch {
            errorMessage = "Your changes could not be saved. Please try again."
            return false
        }
    }
}
