import Foundation

public protocol LoginFormValidating {
    func validate(email: String, password: String) -> AuthValidationError?
}

public struct LoginFormValidator: LoginFormValidating {
    private let minimumPasswordLength: Int

    public init(minimumPasswordLength: Int = 8) {
        self.minimumPasswordLength = minimumPasswordLength
    }

    public func validate(email: String, password: String) -> AuthValidationError? {
        let trimmedEmail = email.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmedEmail.isEmpty {
            return .emptyEmail
        }

        if password.isEmpty {
            return .emptyPassword
        }

        if !Self.isValidEmail(trimmedEmail) {
            return .invalidEmail
        }

        if password.count < minimumPasswordLength {
            return .weakPassword
        }

        return nil
    }

    private static func isValidEmail(_ email: String) -> Bool {
        let pattern = #"^[A-Z0-9._%+-]+@[A-Z0-9.-]+\.[A-Z]{2,}$"#
        return email.range(of: pattern, options: [.regularExpression, .caseInsensitive]) != nil
    }
}
