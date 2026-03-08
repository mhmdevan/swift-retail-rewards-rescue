import Foundation

public enum DSColorPalette {
    public static let backgroundHex = "#F5F7FA"
    public static let surfaceHex = "#FFFFFF"
    public static let textPrimaryHex = "#17212B"
    public static let textSecondaryHex = "#4A5A6A"
    public static let accentHex = "#0057D9"
    public static let dangerHex = "#B00020"
}

#if canImport(UIKit)
import UIKit

public extension UIColor {
    static let dsBackground = UIColor(hex: DSColorPalette.backgroundHex)
    static let dsSurface = UIColor(hex: DSColorPalette.surfaceHex)
    static let dsTextPrimary = UIColor(hex: DSColorPalette.textPrimaryHex)
    static let dsTextSecondary = UIColor(hex: DSColorPalette.textSecondaryHex)
    static let dsAccent = UIColor(hex: DSColorPalette.accentHex)
    static let dsDanger = UIColor(hex: DSColorPalette.dangerHex)

    convenience init(hex: String) {
        let normalized = hex.replacingOccurrences(of: "#", with: "")
        var value: UInt64 = 0
        Scanner(string: normalized).scanHexInt64(&value)
        let red = CGFloat((value & 0xFF0000) >> 16) / 255
        let green = CGFloat((value & 0x00FF00) >> 8) / 255
        let blue = CGFloat(value & 0x0000FF) / 255
        self.init(red: red, green: green, blue: blue, alpha: 1)
    }
}
#endif
