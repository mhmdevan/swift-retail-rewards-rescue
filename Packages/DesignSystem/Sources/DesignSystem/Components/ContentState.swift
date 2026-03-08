import Foundation

public enum ContentState: Equatable {
    case loading(message: String)
    case empty(title: String, message: String)
    case error(title: String, message: String, retryTitle: String)
    case content
}
