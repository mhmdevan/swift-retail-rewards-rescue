import Foundation
import Testing
@testable import Persistence

@Test func mergeAndFetchMessagesKeepsNewestFirst() throws {
    let stack = PersistenceCoreDataStack(inMemory: true)
    let store = CoreDataInboxStore(stack: stack)

    try store.merge(messages: [
        InboxMessage(
            id: "m1",
            title: "First",
            body: "Body1",
            sentAt: Date(timeIntervalSince1970: 1_700_000_000),
            isRead: false,
            deepLink: nil,
            category: "promo"
        ),
        InboxMessage(
            id: "m2",
            title: "Second",
            body: "Body2",
            sentAt: Date(timeIntervalSince1970: 1_700_000_100),
            isRead: false,
            deepLink: "retailrescue://offers/detail/1",
            category: "transactional"
        )
    ])

    let fetched = try store.fetchMessages()

    #expect(fetched.count == 2)
    #expect(fetched.first?.id == "m2")
}

@Test func markReadUpdatesUnreadCount() throws {
    let stack = PersistenceCoreDataStack(inMemory: true)
    let store = CoreDataInboxStore(stack: stack)

    try store.merge(messages: [
        InboxMessage(
            id: "m1",
            title: "Unread",
            body: "Body",
            sentAt: Date(),
            isRead: false,
            deepLink: nil,
            category: "promo"
        )
    ])

    #expect(try store.unreadCount() == 1)

    try store.markRead(messageID: "m1")

    #expect(try store.unreadCount() == 0)
}

@Test func fetchMessageReturnsSpecificMessageByID() throws {
    let stack = PersistenceCoreDataStack(inMemory: true)
    let store = CoreDataInboxStore(stack: stack)

    try store.merge(messages: [
        InboxMessage(
            id: "target",
            title: "Target",
            body: "Body",
            sentAt: Date(),
            isRead: false,
            deepLink: nil,
            category: "promo"
        )
    ])

    let fetched = try store.fetchMessage(id: "target")

    #expect(fetched?.id == "target")
    #expect(fetched?.title == "Target")
}
