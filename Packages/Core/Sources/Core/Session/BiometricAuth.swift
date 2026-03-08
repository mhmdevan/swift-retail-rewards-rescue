import Foundation

public enum BiometricType: Equatable {
    case faceID
    case touchID
    case opticID
    case unknown
}

public enum BiometricAvailability: Equatable {
    case available(type: BiometricType)
    case unavailable(reason: String)
}

public enum BiometricAuthenticationResult: Equatable {
    case success
    case canceled
    case failed(message: String)
    case unavailable(reason: String)
}

public protocol BiometricAuthenticating {
    func availability() -> BiometricAvailability
    func authenticate(reason: String) async -> BiometricAuthenticationResult
}

public enum BiometricGateAction: Equatable {
    case proceedToMainShell
    case allowRetry(message: String)
    case fallbackToPassword(message: String)
}

public struct BiometricGateDecisionEngine {
    public init() {}

    public func action(for result: BiometricAuthenticationResult) -> BiometricGateAction {
        switch result {
        case .success:
            return .proceedToMainShell
        case .canceled:
            return .allowRetry(message: "Authentication was canceled. Try again or use password.")
        case let .failed(message):
            return .allowRetry(message: message)
        case let .unavailable(reason):
            return .fallbackToPassword(message: reason)
        }
    }
}
