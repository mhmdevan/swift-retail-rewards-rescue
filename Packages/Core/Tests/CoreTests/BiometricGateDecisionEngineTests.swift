import Testing
@testable import Core

@Test func decisionReturnsProceedForSuccess() {
    let sut = BiometricGateDecisionEngine()

    #expect(sut.action(for: .success) == .proceedToMainShell)
}

@Test func decisionReturnsRetryForCanceled() {
    let sut = BiometricGateDecisionEngine()

    #expect(
        sut.action(for: .canceled) ==
            .allowRetry(message: "Authentication was canceled. Try again or use password.")
    )
}

@Test func decisionReturnsRetryForFailure() {
    let sut = BiometricGateDecisionEngine()

    #expect(sut.action(for: .failed(message: "Denied")) == .allowRetry(message: "Denied"))
}

@Test func decisionReturnsFallbackWhenUnavailable() {
    let sut = BiometricGateDecisionEngine()

    #expect(sut.action(for: .unavailable(reason: "No biometrics")) == .fallbackToPassword(message: "No biometrics"))
}
