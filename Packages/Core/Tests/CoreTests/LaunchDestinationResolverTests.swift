import Foundation
import Testing
@testable import Core

@Test func resolveReturnsLoginWhenSessionMissing() {
    let sut = LaunchDestinationResolver()

    #expect(sut.resolve(session: nil) == .login)
}

@Test func resolveReturnsMainShellWhenBiometricDisabled() {
    let sut = LaunchDestinationResolver()
    let session = UserSession(
        userId: "1",
        email: "demo@retailrescue.app",
        authToken: "token",
        refreshToken: "refresh",
        biometricEnabled: false,
        lastLoginDate: Date()
    )

    #expect(sut.resolve(session: session) == .mainShell)
}

@Test func resolveReturnsBiometricUnlockWhenBiometricEnabled() {
    let sut = LaunchDestinationResolver()
    let session = UserSession(
        userId: "1",
        email: "demo@retailrescue.app",
        authToken: "token",
        refreshToken: "refresh",
        biometricEnabled: true,
        lastLoginDate: Date()
    )

    #expect(sut.resolve(session: session) == .biometricUnlock)
}
