import Foundation

public struct UserSession: Equatable, Codable {
    public let userId: String
    public let email: String
    public let authToken: String
    public let refreshToken: String
    public let biometricEnabled: Bool
    public let lastLoginDate: Date

    public init(
        userId: String,
        email: String,
        authToken: String,
        refreshToken: String,
        biometricEnabled: Bool,
        lastLoginDate: Date
    ) {
        self.userId = userId
        self.email = email
        self.authToken = authToken
        self.refreshToken = refreshToken
        self.biometricEnabled = biometricEnabled
        self.lastLoginDate = lastLoginDate
    }
}
