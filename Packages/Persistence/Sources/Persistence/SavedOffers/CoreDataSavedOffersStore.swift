import CoreData
import FeaturesOffers
import Foundation

public enum SavedOffersSortOption {
    case expiryDateAscending
    case savedDateDescending
}

public protocol SavedOffersStoring {
    func save(_ offer: OfferSummary) throws
    func unsave(offerID: String) throws
    func isSaved(offerID: String) throws -> Bool
    func fetchSavedOfferIDs() throws -> Set<String>
    func fetchSavedOffers(sortedBy: SavedOffersSortOption) throws -> [OfferSummary]
    func reconcileExpiredOffers(referenceDate: Date) throws -> [String]
    func makeFetchedResultsController(sortedBy: SavedOffersSortOption) -> NSFetchedResultsController<NSManagedObject>
}

public final class CoreDataSavedOffersStore: SavedOffersStoring {
    private let stack: PersistenceCoreDataStack

    public init(stack: PersistenceCoreDataStack) {
        self.stack = stack
    }

    public func save(_ offer: OfferSummary) throws {
        let context = stack.persistentContainer.viewContext

        let request = fetchRequestByID(offer.id)
        let object = (try? context.fetch(request).first) ?? NSEntityDescription.insertNewObject(
            forEntityName: "SavedOfferEntity",
            into: context
        )

        object.setValue(offer.id, forKey: "id")
        object.setValue(offer.title, forKey: "title")
        object.setValue(offer.subtitle, forKey: "subtitle")
        object.setValue(offer.imageURL?.absoluteString, forKey: "imageURLString")
        object.setValue(offer.expiryDate, forKey: "expiryDate")
        object.setValue((object.value(forKey: "savedAt") as? Date) ?? Date(), forKey: "savedAt")
        object.setValue(Date(), forKey: "updatedAt")

        do {
            try context.save()
        } catch {
            throw PersistenceError.saveFailed
        }
    }

    public func unsave(offerID: String) throws {
        let context = stack.persistentContainer.viewContext
        do {
            let request = fetchRequestByID(offerID)
            let objects = try context.fetch(request)
            objects.forEach(context.delete)
            try context.save()
        } catch {
            throw PersistenceError.deleteFailed
        }
    }

    public func isSaved(offerID: String) throws -> Bool {
        let context = stack.persistentContainer.viewContext
        let request = fetchRequestByID(offerID)
        request.fetchLimit = 1

        do {
            return try context.count(for: request) > 0
        } catch {
            throw PersistenceError.fetchFailed
        }
    }

    public func fetchSavedOffers(sortedBy: SavedOffersSortOption) throws -> [OfferSummary] {
        let context = stack.persistentContainer.viewContext
        let request = NSFetchRequest<NSManagedObject>(entityName: "SavedOfferEntity")
        request.sortDescriptors = sortDescriptors(for: sortedBy)

        do {
            let objects = try context.fetch(request)
            return objects.compactMap(Self.mapToOfferSummary)
        } catch {
            throw PersistenceError.fetchFailed
        }
    }

    public func fetchSavedOfferIDs() throws -> Set<String> {
        let context = stack.persistentContainer.viewContext
        let request = NSFetchRequest<NSManagedObject>(entityName: "SavedOfferEntity")

        do {
            let objects = try context.fetch(request)
            let ids = objects.compactMap { $0.value(forKey: "id") as? String }
            return Set(ids)
        } catch {
            throw PersistenceError.fetchFailed
        }
    }

    public func reconcileExpiredOffers(referenceDate: Date) throws -> [String] {
        let context = stack.persistentContainer.viewContext
        let request = NSFetchRequest<NSManagedObject>(entityName: "SavedOfferEntity")
        request.predicate = NSPredicate(format: "expiryDate < %@", referenceDate as NSDate)

        do {
            let expired = try context.fetch(request)
            let ids = expired.compactMap { $0.value(forKey: "id") as? String }
            expired.forEach(context.delete)
            if !expired.isEmpty {
                try context.save()
            }
            return ids
        } catch {
            throw PersistenceError.deleteFailed
        }
    }

    public func makeFetchedResultsController(sortedBy: SavedOffersSortOption) -> NSFetchedResultsController<NSManagedObject> {
        let request = NSFetchRequest<NSManagedObject>(entityName: "SavedOfferEntity")
        request.sortDescriptors = sortDescriptors(for: sortedBy)

        return NSFetchedResultsController(
            fetchRequest: request,
            managedObjectContext: stack.persistentContainer.viewContext,
            sectionNameKeyPath: nil,
            cacheName: nil
        )
    }

    private func fetchRequestByID(_ id: String) -> NSFetchRequest<NSManagedObject> {
        let request = NSFetchRequest<NSManagedObject>(entityName: "SavedOfferEntity")
        request.predicate = NSPredicate(format: "id == %@", id)
        return request
    }

    private func sortDescriptors(for option: SavedOffersSortOption) -> [NSSortDescriptor] {
        switch option {
        case .expiryDateAscending:
            return [NSSortDescriptor(key: "expiryDate", ascending: true)]
        case .savedDateDescending:
            return [NSSortDescriptor(key: "savedAt", ascending: false)]
        }
    }

    private static func mapToOfferSummary(_ object: NSManagedObject) -> OfferSummary? {
        guard
            let id = object.value(forKey: "id") as? String,
            let title = object.value(forKey: "title") as? String,
            let subtitle = object.value(forKey: "subtitle") as? String,
            let expiryDate = object.value(forKey: "expiryDate") as? Date
        else {
            return nil
        }

        let imageURLString = object.value(forKey: "imageURLString") as? String
        return OfferSummary(
            id: id,
            title: title,
            subtitle: subtitle,
            imageURL: imageURLString.flatMap(URL.init(string:)),
            expiryDate: expiryDate,
            isSaved: true,
            isExpired: expiryDate < Date()
        )
    }
}
