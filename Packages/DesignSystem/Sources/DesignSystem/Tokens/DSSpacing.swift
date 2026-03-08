import Foundation

#if canImport(CoreGraphics)
import CoreGraphics
public typealias DSSpacingValue = CGFloat
#else
public typealias DSSpacingValue = Double
#endif

public enum DSSpacing {
    public static let xxs: DSSpacingValue = 4
    public static let xs: DSSpacingValue = 8
    public static let sm: DSSpacingValue = 12
    public static let md: DSSpacingValue = 16
    public static let lg: DSSpacingValue = 24
    public static let xl: DSSpacingValue = 32
}
