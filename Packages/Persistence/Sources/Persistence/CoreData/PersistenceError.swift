import Foundation

public enum PersistenceError: Error, Equatable, LocalizedError {
    case saveFailed
    case fetchFailed
    case deleteFailed

    public var errorDescription: String? {
        switch self {
        case .saveFailed:
            return "Failed to save persisted data."
        case .fetchFailed:
            return "Failed to fetch persisted data."
        case .deleteFailed:
            return "Failed to delete persisted data."
        }
    }
}
