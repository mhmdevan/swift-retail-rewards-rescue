import Core
import Foundation
import LocalAuthentication

final class LocalBiometricAuthenticator: BiometricAuthenticating {
    private let contextFactory: () -> LAContext

    init(contextFactory: @escaping () -> LAContext = { LAContext() }) {
        self.contextFactory = contextFactory
    }

    func availability() -> BiometricAvailability {
        let context = contextFactory()
        var evaluationError: NSError?

        let canEvaluate = context.canEvaluatePolicy(
            .deviceOwnerAuthenticationWithBiometrics,
            error: &evaluationError
        )

        guard canEvaluate else {
            let reason = evaluationError?.localizedDescription ?? "Biometric authentication is unavailable on this device."
            return .unavailable(reason: reason)
        }

        return .available(type: mapBiometricType(context.biometryType))
    }

    func authenticate(reason: String) async -> BiometricAuthenticationResult {
        let context = contextFactory()
        var evaluationError: NSError?

        guard context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &evaluationError) else {
            let reason = evaluationError?.localizedDescription ?? "Biometric authentication is unavailable."
            return .unavailable(reason: reason)
        }

        do {
            let isAuthenticated = try await context.evaluatePolicy(
                .deviceOwnerAuthenticationWithBiometrics,
                localizedReason: reason
            )
            return isAuthenticated ? .success : .failed(message: "Biometric authentication failed.")
        } catch {
            guard let laError = error as? LAError else {
                return .failed(message: error.localizedDescription)
            }

            switch laError.code {
            case .userCancel, .userFallback, .systemCancel, .appCancel:
                return .canceled
            case .biometryNotAvailable, .biometryNotEnrolled, .biometryLockout:
                return .unavailable(reason: laError.localizedDescription)
            default:
                return .failed(message: laError.localizedDescription)
            }
        }
    }

    private func mapBiometricType(_ type: LABiometryType) -> BiometricType {
        if #available(iOS 17.0, *), type == .opticID {
            return .opticID
        }

        switch type {
        case .faceID:
            return .faceID
        case .touchID:
            return .touchID
        default:
            return .unknown
        }
    }
}
