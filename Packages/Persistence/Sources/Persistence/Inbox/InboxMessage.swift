import Foundation

public struct InboxMessage: Equatable, Sendable {
    public let id: String
    public let title: String
    public let body: String
    public let sentAt: Date
    public let isRead: Bool
    public let deepLink: String?
    public let category: String

    public init(
        id: String,
        title: String,
        body: String,
        sentAt: Date,
        isRead: Bool,
        deepLink: String?,
        category: String
    ) {
        self.id = id
        self.title = title
        self.body = body
        self.sentAt = sentAt
        self.isRead = isRead
        self.deepLink = deepLink
        self.category = category
    }
}
