import Foundation

public enum AuthValidationError: LocalizedError, Equatable {
    case emptyEmail
    case emptyPassword
    case invalidEmail
    case weakPassword
    case rejectedCredentials

    public var errorDescription: String? {
        switch self {
        case .emptyEmail:
            return "Email is required."
        case .emptyPassword:
            return "Password is required."
        case .invalidEmail:
            return "Please enter a valid email address."
        case .weakPassword:
            return "Password must be at least 8 characters."
        case .rejectedCredentials:
            return "Credentials were rejected. Try demo@retailrescue.app / password123."
        }
    }
}

public protocol AuthServicing {
    func login(email: String, password: String) async throws -> UserSession
}

public struct MockAuthService: AuthServicing {
    private let validator: any LoginFormValidating
    private let delayNanoseconds: UInt64

    public init(
        validator: any LoginFormValidating = LoginFormValidator(),
        delayNanoseconds: UInt64 = 350_000_000
    ) {
        self.validator = validator
        self.delayNanoseconds = delayNanoseconds
    }

    public func login(email: String, password: String) async throws -> UserSession {
        if delayNanoseconds > 0 {
            try? await Task.sleep(nanoseconds: delayNanoseconds)
        }

        if let validationError = validator.validate(email: email, password: password) {
            throw validationError
        }

        guard email.lowercased() == "demo@retailrescue.app", password == "password123" else {
            throw AuthValidationError.rejectedCredentials
        }

        return UserSession(
            userId: "demo-user",
            email: email,
            authToken: "mock-auth-token",
            refreshToken: "mock-refresh-token",
            biometricEnabled: false,
            lastLoginDate: Date()
        )
    }
}
