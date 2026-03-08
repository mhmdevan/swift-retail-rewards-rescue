import Foundation

public enum LaunchDestination: Equatable {
    case login
    case mainShell
    case biometricUnlock
}

public struct LaunchDestinationResolver {
    public init() {}

    public func resolve(session: UserSession?) -> LaunchDestination {
        guard let session else {
            return .login
        }

        return session.biometricEnabled ? .biometricUnlock : .mainShell
    }
}
