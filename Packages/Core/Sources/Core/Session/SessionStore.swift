import Foundation

public protocol SessionStoring: AnyObject {
    var currentSession: UserSession? { get }

    @discardableResult
    func restore() -> UserSession?

    func save(_ session: UserSession) throws
    func clear() throws
}

public final class InMemorySessionStore: SessionStoring {
    public private(set) var currentSession: UserSession?

    public init(currentSession: UserSession? = nil) {
        self.currentSession = currentSession
    }

    @discardableResult
    public func restore() -> UserSession? {
        currentSession
    }

    public func save(_ session: UserSession) throws {
        currentSession = session
    }

    public func clear() throws {
        currentSession = nil
    }
}
