# RYUOS Messenger integration

Current mode is an offline demo. Sample contacts are fictional. Drafts, read state, and queued replies persist locally under `ryuos.messenger.v1` in UserDefaults. Nothing is uploaded. Demo identifiers and queued messages must never be migrated into a real account automatically.

## Connection point

`MessengerAPI.swift` defines an async service protocol and an inactive `RailwayMessengerAPI` URLSession implementation. The view uses `MessengerStore`, so UI code does not depend on networking. Before enabling real messaging, inject a service into the store and replace demo storage with account-scoped conversations and an explicit outbox. The client is a proposed contract, not a deployed or verified backend.

Proposed routes relative to your HTTPS base URL:

| Route | Response |
| --- | --- |
| GET /v1/conversations | Array of ChatConversation objects |
| POST /v1/conversations/{id}/messages | Server-acknowledged ChatMessage |

POST body: `{"clientMessageID":"UUID","text":"Hello"}`. Requests carry a Bearer user access token and POST uses the UUID as an Idempotency-Key. Backend must enforce conversation membership, validate message size, and deduplicate keys. Dates use ISO 8601; message statuses are received, queued, or sent. ChatConversation currently contains id, name, symbol, unreadCount, messages, and draft; use server-specific DTOs when your real contract is defined, keeping draft local.

Next integration steps: provide the base URL and schema; implement user sign-in and Keychain token storage; add paginated message retrieval, loading/error/retry states, account-scoped cache, explicit authenticated outbox synchronization, and server acknowledgements before displaying Sent. Define refresh/push behavior separately. Do not place Railway management keys or backend credentials in the Watch app.

The app does not connect to LINE or provide LINE account access. Current scope is text conversations, native Watch text entry, quick replies, emoji, unread badges, and persistent drafts. Voice recordings, images, stickers, calls, and push notifications are not implemented.
