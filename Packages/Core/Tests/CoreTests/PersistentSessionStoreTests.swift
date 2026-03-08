import Foundation
import Testing
@testable import Core

@Test func saveThenRestoreReturnsSession() throws {
    let secureStore = InMemorySecureDataStore()
    let sut = PersistentSessionStore(secureStore: secureStore)
    let session = UserSession(
        userId: "demo-user",
        email: "demo@retailrescue.app",
        authToken: "token",
        refreshToken: "refresh",
        biometricEnabled: true,
        lastLoginDate: Date(timeIntervalSince1970: 1_700_000_000)
    )

    try sut.save(session)

    let restored = sut.restore()

    #expect(restored == session)
    #expect(sut.currentSession == session)
}

@Test func clearRemovesPersistedSession() throws {
    let secureStore = InMemorySecureDataStore()
    let sut = PersistentSessionStore(secureStore: secureStore)
    let session = UserSession(
        userId: "demo-user",
        email: "demo@retailrescue.app",
        authToken: "token",
        refreshToken: "refresh",
        biometricEnabled: false,
        lastLoginDate: Date()
    )

    try sut.save(session)
    try sut.clear()

    #expect(sut.currentSession == nil)
    #expect(sut.restore() == nil)
}

@Test func restoreClearsCorruptedPayload() throws {
    let secureStore = InMemorySecureDataStore()
    let key = "retail_rewards_rescue_session"
    try secureStore.write(Data("invalid-json".utf8), for: key)

    let sut = PersistentSessionStore(secureStore: secureStore, storageKey: key)
    let restored = sut.restore()

    #expect(restored == nil)
    #expect(try secureStore.read(for: key) == nil)
}

@Test func saveThrowsWhenSecureStoreWriteFails() {
    let secureStore = InMemorySecureDataStore()
    secureStore.shouldFailWrites = true
    let sut = PersistentSessionStore(secureStore: secureStore)
    let session = UserSession(
        userId: "demo-user",
        email: "demo@retailrescue.app",
        authToken: "token",
        refreshToken: "refresh",
        biometricEnabled: false,
        lastLoginDate: Date()
    )

    #expect(throws: SessionPersistenceError.secureStoreWriteFailed) {
        try sut.save(session)
    }
}

private final class InMemorySecureDataStore: SecureDataStoring {
    enum TestError: Error {
        case forcedFailure
    }

    var shouldFailWrites = false
    private var storage: [String: Data] = [:]

    func read(for key: String) throws -> Data? {
        storage[key]
    }

    func write(_ data: Data, for key: String) throws {
        if shouldFailWrites {
            throw TestError.forcedFailure
        }

        storage[key] = data
    }

    func delete(for key: String) throws {
        storage[key] = nil
    }
}
