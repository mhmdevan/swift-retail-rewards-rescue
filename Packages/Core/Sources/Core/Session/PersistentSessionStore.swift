import Foundation

public enum SessionPersistenceError: LocalizedError, Equatable {
    case encodingFailed
    case secureStoreWriteFailed
    case secureStoreDeleteFailed

    public var errorDescription: String? {
        switch self {
        case .encodingFailed:
            return "Unable to encode user session for secure persistence."
        case .secureStoreWriteFailed:
            return "Unable to save session to secure storage."
        case .secureStoreDeleteFailed:
            return "Unable to clear session from secure storage."
        }
    }
}

public final class PersistentSessionStore: SessionStoring {
    public private(set) var currentSession: UserSession?

    private let secureStore: SecureDataStoring
    private let storageKey: String
    private let encoder: JSONEncoder
    private let decoder: JSONDecoder

    public init(
        secureStore: SecureDataStoring,
        storageKey: String = "retail_rewards_rescue_session",
        encoder: JSONEncoder = .init(),
        decoder: JSONDecoder = .init(),
        restoreOnInit: Bool = false
    ) {
        self.secureStore = secureStore
        self.storageKey = storageKey
        self.encoder = encoder
        self.decoder = decoder

        if restoreOnInit {
            _ = restore()
        }
    }

    @discardableResult
    public func restore() -> UserSession? {
        do {
            guard let rawData = try secureStore.read(for: storageKey) else {
                currentSession = nil
                return nil
            }

            let session = try decoder.decode(UserSession.self, from: rawData)
            currentSession = session
            return session
        } catch {
            currentSession = nil
            try? secureStore.delete(for: storageKey)
            return nil
        }
    }

    public func save(_ session: UserSession) throws {
        let rawData: Data
        do {
            rawData = try encoder.encode(session)
        } catch {
            throw SessionPersistenceError.encodingFailed
        }

        do {
            try secureStore.write(rawData, for: storageKey)
            currentSession = session
        } catch {
            throw SessionPersistenceError.secureStoreWriteFailed
        }
    }

    public func clear() throws {
        do {
            try secureStore.delete(for: storageKey)
            currentSession = nil
        } catch {
            throw SessionPersistenceError.secureStoreDeleteFailed
        }
    }
}
