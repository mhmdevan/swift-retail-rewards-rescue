import Testing
@testable import Core

@Test func loginSucceedsForDemoCredentials() async throws {
    let sut = MockAuthService(delayNanoseconds: 0)

    let session = try await sut.login(email: "demo@retailrescue.app", password: "password123")

    #expect(session.userId == "demo-user")
    #expect(session.email == "demo@retailrescue.app")
}

@Test func loginFailsForEmptyEmail() async {
    let sut = MockAuthService(delayNanoseconds: 0)

    await #expect(throws: AuthValidationError.emptyEmail) {
        try await sut.login(email: "", password: "password123")
    }
}

@Test func loginFailsForInvalidEmail() async {
    let sut = MockAuthService(delayNanoseconds: 0)

    await #expect(throws: AuthValidationError.invalidEmail) {
        try await sut.login(email: "demo", password: "password123")
    }
}

@Test func loginFailsForWeakPassword() async {
    let sut = MockAuthService(delayNanoseconds: 0)

    await #expect(throws: AuthValidationError.weakPassword) {
        try await sut.login(email: "demo@retailrescue.app", password: "short")
    }
}

@Test func loginFailsForRejectedCredentials() async {
    let sut = MockAuthService(delayNanoseconds: 0)

    await #expect(throws: AuthValidationError.rejectedCredentials) {
        try await sut.login(email: "user@retailrescue.app", password: "password123")
    }
}
