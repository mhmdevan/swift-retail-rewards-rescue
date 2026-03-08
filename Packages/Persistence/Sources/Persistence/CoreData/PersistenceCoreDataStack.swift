import CoreData
import Foundation

public final class PersistenceCoreDataStack {
    public static let modelName = "RetailRewardsRescueModel"

    public let persistentContainer: NSPersistentContainer

    public init(inMemory: Bool = false) {
        let model = Self.makeManagedObjectModel()
        persistentContainer = NSPersistentContainer(name: Self.modelName, managedObjectModel: model)

        if inMemory {
            let description = NSPersistentStoreDescription()
            description.type = NSInMemoryStoreType
            persistentContainer.persistentStoreDescriptions = [description]
        }

        persistentContainer.loadPersistentStores { _, _ in }

        persistentContainer.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        persistentContainer.viewContext.automaticallyMergesChangesFromParent = true
    }

    public func performBackgroundTask(_ block: @escaping (NSManagedObjectContext) -> Void) {
        persistentContainer.performBackgroundTask(block)
    }

    private static func makeManagedObjectModel() -> NSManagedObjectModel {
        let model = NSManagedObjectModel()

        let savedOfferEntity = NSEntityDescription()
        savedOfferEntity.name = "SavedOfferEntity"
        savedOfferEntity.managedObjectClassName = NSStringFromClass(NSManagedObject.self)
        savedOfferEntity.properties = [
            makeAttribute(name: "id", type: .stringAttributeType, isOptional: false),
            makeAttribute(name: "title", type: .stringAttributeType, isOptional: false),
            makeAttribute(name: "subtitle", type: .stringAttributeType, isOptional: false),
            makeAttribute(name: "imageURLString", type: .stringAttributeType, isOptional: true),
            makeAttribute(name: "expiryDate", type: .dateAttributeType, isOptional: false),
            makeAttribute(name: "savedAt", type: .dateAttributeType, isOptional: false),
            makeAttribute(name: "updatedAt", type: .dateAttributeType, isOptional: false)
        ]

        let inboxEntity = NSEntityDescription()
        inboxEntity.name = "InboxMessageEntity"
        inboxEntity.managedObjectClassName = NSStringFromClass(NSManagedObject.self)
        inboxEntity.properties = [
            makeAttribute(name: "id", type: .stringAttributeType, isOptional: false),
            makeAttribute(name: "title", type: .stringAttributeType, isOptional: false),
            makeAttribute(name: "body", type: .stringAttributeType, isOptional: false),
            makeAttribute(name: "sentAt", type: .dateAttributeType, isOptional: false),
            makeAttribute(name: "isRead", type: .booleanAttributeType, isOptional: false),
            makeAttribute(name: "deepLink", type: .stringAttributeType, isOptional: true),
            makeAttribute(name: "category", type: .stringAttributeType, isOptional: false),
            makeAttribute(name: "updatedAt", type: .dateAttributeType, isOptional: false)
        ]

        model.entities = [savedOfferEntity, inboxEntity]
        return model
    }

    private static func makeAttribute(
        name: String,
        type: NSAttributeType,
        isOptional: Bool
    ) -> NSAttributeDescription {
        let attribute = NSAttributeDescription()
        attribute.name = name
        attribute.attributeType = type
        attribute.isOptional = isOptional
        return attribute
    }
}
