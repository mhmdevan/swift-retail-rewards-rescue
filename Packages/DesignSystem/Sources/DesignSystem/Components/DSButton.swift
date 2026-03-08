import Foundation

#if canImport(UIKit)
import UIKit

public final class DSButton: UIButton {
    public override init(frame: CGRect) {
        super.init(frame: frame)
        configure()
    }

    public required init?(coder: NSCoder) {
        super.init(coder: coder)
        configure()
    }

    private func configure() {
        backgroundColor = .dsAccent
        setTitleColor(.white, for: .normal)
        titleLabel?.font = DSTypography.subtitle()
        layer.cornerRadius = 10
        contentEdgeInsets = UIEdgeInsets(top: 12, left: 16, bottom: 12, right: 16)
        accessibilityTraits = [.button]
    }
}
#else
public final class DSButton {
    public init() {}
}
#endif
