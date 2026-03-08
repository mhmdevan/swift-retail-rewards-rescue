import Foundation

#if canImport(UIKit)
import UIKit

public enum DSTypography {
    public static func title() -> UIFont {
        .systemFont(ofSize: 24, weight: .bold)
    }

    public static func subtitle() -> UIFont {
        .systemFont(ofSize: 17, weight: .semibold)
    }

    public static func body() -> UIFont {
        .systemFont(ofSize: 16, weight: .regular)
    }

    public static func caption() -> UIFont {
        .systemFont(ofSize: 13, weight: .regular)
    }
}
#else
public struct DSFont: Equatable {
    public let size: Double
    public let weight: String

    public init(size: Double, weight: String) {
        self.size = size
        self.weight = weight
    }
}

public enum DSTypography {
    public static func title() -> DSFont {
        DSFont(size: 24, weight: "bold")
    }

    public static func subtitle() -> DSFont {
        DSFont(size: 17, weight: "semibold")
    }

    public static func body() -> DSFont {
        DSFont(size: 16, weight: "regular")
    }

    public static func caption() -> DSFont {
        DSFont(size: 13, weight: "regular")
    }
}
#endif
