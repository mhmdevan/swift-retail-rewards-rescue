import CoreData
import Foundation

public protocol InboxStoring {
    func merge(messages: [InboxMessage]) throws
    func fetchMessages() throws -> [InboxMessage]
    func fetchMessage(id: String) throws -> InboxMessage?
    func markRead(messageID: String) throws
    func unreadCount() throws -> Int
    func makeFetchedResultsController() -> NSFetchedResultsController<NSManagedObject>
}

public final class CoreDataInboxStore: InboxStoring {
    private let stack: PersistenceCoreDataStack

    public init(stack: PersistenceCoreDataStack) {
        self.stack = stack
    }

    public func merge(messages: [InboxMessage]) throws {
        let context = stack.persistentContainer.viewContext

        do {
            for message in messages {
                let request = fetchRequestByID(message.id)
                let object = (try context.fetch(request).first) ?? NSEntityDescription.insertNewObject(
                    forEntityName: "InboxMessageEntity",
                    into: context
                )

                object.setValue(message.id, forKey: "id")
                object.setValue(message.title, forKey: "title")
                object.setValue(message.body, forKey: "body")
                object.setValue(message.sentAt, forKey: "sentAt")
                object.setValue(message.isRead, forKey: "isRead")
                object.setValue(message.deepLink, forKey: "deepLink")
                object.setValue(message.category, forKey: "category")
                object.setValue(Date(), forKey: "updatedAt")
            }

            try context.save()
        } catch {
            throw PersistenceError.saveFailed
        }
    }

    public func fetchMessages() throws -> [InboxMessage] {
        let request = NSFetchRequest<NSManagedObject>(entityName: "InboxMessageEntity")
        request.sortDescriptors = [NSSortDescriptor(key: "sentAt", ascending: false)]

        do {
            return try stack.persistentContainer.viewContext.fetch(request).compactMap(Self.mapObject)
        } catch {
            throw PersistenceError.fetchFailed
        }
    }

    public func fetchMessage(id: String) throws -> InboxMessage? {
        let request = fetchRequestByID(id)
        request.fetchLimit = 1

        do {
            let object = try stack.persistentContainer.viewContext.fetch(request).first
            return object.flatMap(Self.mapObject)
        } catch {
            throw PersistenceError.fetchFailed
        }
    }

    public func markRead(messageID: String) throws {
        let context = stack.persistentContainer.viewContext
        do {
            let request = fetchRequestByID(messageID)
            request.fetchLimit = 1
            guard let object = try context.fetch(request).first else {
                return
            }
            object.setValue(true, forKey: "isRead")
            object.setValue(Date(), forKey: "updatedAt")
            try context.save()
        } catch {
            throw PersistenceError.saveFailed
        }
    }

    public func unreadCount() throws -> Int {
        let request = NSFetchRequest<NSManagedObject>(entityName: "InboxMessageEntity")
        request.predicate = NSPredicate(format: "isRead == NO")

        do {
            return try stack.persistentContainer.viewContext.count(for: request)
        } catch {
            throw PersistenceError.fetchFailed
        }
    }

    public func makeFetchedResultsController() -> NSFetchedResultsController<NSManagedObject> {
        let request = NSFetchRequest<NSManagedObject>(entityName: "InboxMessageEntity")
        request.sortDescriptors = [NSSortDescriptor(key: "sentAt", ascending: false)]

        return NSFetchedResultsController(
            fetchRequest: request,
            managedObjectContext: stack.persistentContainer.viewContext,
            sectionNameKeyPath: nil,
            cacheName: nil
        )
    }

    private func fetchRequestByID(_ id: String) -> NSFetchRequest<NSManagedObject> {
        let request = NSFetchRequest<NSManagedObject>(entityName: "InboxMessageEntity")
        request.predicate = NSPredicate(format: "id == %@", id)
        return request
    }

    private static func mapObject(_ object: NSManagedObject) -> InboxMessage? {
        guard
            let id = object.value(forKey: "id") as? String,
            let title = object.value(forKey: "title") as? String,
            let body = object.value(forKey: "body") as? String,
            let sentAt = object.value(forKey: "sentAt") as? Date,
            let category = object.value(forKey: "category") as? String,
            let isRead = object.value(forKey: "isRead") as? Bool
        else {
            return nil
        }

        return InboxMessage(
            id: id,
            title: title,
            body: body,
            sentAt: sentAt,
            isRead: isRead,
            deepLink: object.value(forKey: "deepLink") as? String,
            category: category
        )
    }
}
