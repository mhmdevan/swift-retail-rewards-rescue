import Foundation

public enum AppRoute: Equatable {
    case offers
    case offerDetail(id: String)
    case inbox
    case inboxMessage(id: String)
    case wallet
}
