import Foundation

#if canImport(UIKit)
import UIKit

public final class ListStateContainerView: UIView {
    public let contentView = UIView()
    public let stateView = ContentStateView()

    public override init(frame: CGRect) {
        super.init(frame: frame)
        configure()
    }

    public required init?(coder: NSCoder) {
        super.init(coder: coder)
        configure()
    }

    public func setState(_ state: ContentState) {
        stateView.render(state)
    }

    private func configure() {
        backgroundColor = .dsBackground

        contentView.translatesAutoresizingMaskIntoConstraints = false
        stateView.translatesAutoresizingMaskIntoConstraints = false

        addSubview(contentView)
        addSubview(stateView)

        NSLayoutConstraint.activate([
            contentView.topAnchor.constraint(equalTo: topAnchor),
            contentView.leadingAnchor.constraint(equalTo: leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: trailingAnchor),
            contentView.bottomAnchor.constraint(equalTo: bottomAnchor),

            stateView.topAnchor.constraint(equalTo: topAnchor),
            stateView.leadingAnchor.constraint(equalTo: leadingAnchor),
            stateView.trailingAnchor.constraint(equalTo: trailingAnchor),
            stateView.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])

        stateView.render(.content)
    }
}
#else
public final class ListStateContainerView {
    public init() {}
    public func setState(_ state: ContentState) {}
}
#endif
