import Foundation

// Integration boundary for your future Railway backend. Offline demo mode never
// constructs this client or uploads sample chats. Replace the proposed routes
// and DTOs below when the backend contract is ready.
protocol MessengerAPI: Sendable {
    func conversations() async throws -> [ChatConversation]
    func send(_ message: ChatMessage, conversationID: String) async throws -> ChatMessage
}

enum MessengerAPIError: Error {
    case invalidBaseURL
    case invalidResponse
    case httpStatus(Int)
}

struct RailwayMessengerAPI: MessengerAPI {
    let baseURL: URL
    // Supply a short-lived user access token from your future sign-in flow.
    // Never embed Railway management tokens or server secrets in the Watch app.
    let accessToken: @Sendable () async throws -> String

    init(baseURL: URL, accessToken: @escaping @Sendable () async throws -> String) throws {
        guard baseURL.scheme == "https", baseURL.host != nil,
              baseURL.user == nil, baseURL.password == nil else {
            throw MessengerAPIError.invalidBaseURL
        }
        self.baseURL = baseURL
        self.accessToken = accessToken
    }

    func conversations() async throws -> [ChatConversation] {
        let request = try await authorizedRequest(path: ["v1", "conversations"])
        return try await perform(request)
    }

    func send(_ message: ChatMessage, conversationID: String) async throws -> ChatMessage {
        var request = try await authorizedRequest(path: ["v1", "conversations", conversationID, "messages"])
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        // Backend must deduplicate this key before a retry can be enabled.
        request.setValue(message.id.uuidString, forHTTPHeaderField: "Idempotency-Key")
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        request.httpBody = try encoder.encode(SendMessageRequest(clientMessageID: message.id, text: message.text))
        return try await perform(request)
    }

    private func authorizedRequest(path: [String]) async throws -> URLRequest {
        let url = path.reduce(baseURL) { $0.appendingPathComponent($1) }
        var request = URLRequest(url: url)
        request.timeoutInterval = 20
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue("Bearer \(try await accessToken())", forHTTPHeaderField: "Authorization")
        return request
    }

    private func perform<T: Decodable>(_ request: URLRequest) async throws -> T {
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let response = response as? HTTPURLResponse else { throw MessengerAPIError.invalidResponse }
        guard (200..<300).contains(response.statusCode) else { throw MessengerAPIError.httpStatus(response.statusCode) }
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try decoder.decode(T.self, from: data)
    }

    private struct SendMessageRequest: Encodable {
        let clientMessageID: UUID
        let text: String
    }
}
