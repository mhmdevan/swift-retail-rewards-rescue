import Foundation

#if canImport(UIKit)
import UIKit

public final class ContentStateView: UIView {
    public var onRetry: (() -> Void)?

    private let activityIndicator = UIActivityIndicatorView(style: .large)
    private let titleLabel = UILabel()
    private let messageLabel = UILabel()
    private let retryButton = DSButton(frame: .zero)
    private let stackView = UIStackView()

    public override init(frame: CGRect) {
        super.init(frame: frame)
        configure()
    }

    public required init?(coder: NSCoder) {
        super.init(coder: coder)
        configure()
    }

    public func render(_ state: ContentState) {
        switch state {
        case let .loading(message):
            activityIndicator.startAnimating()
            titleLabel.text = message
            messageLabel.text = nil
            retryButton.isHidden = true
            isHidden = false
        case let .empty(title, message):
            activityIndicator.stopAnimating()
            titleLabel.text = title
            messageLabel.text = message
            retryButton.isHidden = true
            isHidden = false
        case let .error(title, message, retryTitle):
            activityIndicator.stopAnimating()
            titleLabel.text = title
            messageLabel.text = message
            retryButton.setTitle(retryTitle, for: .normal)
            retryButton.isHidden = false
            isHidden = false
        case .content:
            activityIndicator.stopAnimating()
            isHidden = true
        }
    }

    private func configure() {
        backgroundColor = .clear

        titleLabel.font = DSTypography.subtitle()
        titleLabel.textColor = .dsTextPrimary
        titleLabel.textAlignment = .center
        titleLabel.numberOfLines = 0

        messageLabel.font = DSTypography.body()
        messageLabel.textColor = .dsTextSecondary
        messageLabel.textAlignment = .center
        messageLabel.numberOfLines = 0

        retryButton.isHidden = true
        retryButton.addTarget(self, action: #selector(retryTapped), for: .touchUpInside)

        stackView.axis = .vertical
        stackView.alignment = .center
        stackView.spacing = DSSpacing.md
        stackView.translatesAutoresizingMaskIntoConstraints = false

        [activityIndicator, titleLabel, messageLabel, retryButton].forEach { stackView.addArrangedSubview($0) }

        addSubview(stackView)

        NSLayoutConstraint.activate([
            stackView.centerYAnchor.constraint(equalTo: centerYAnchor),
            stackView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: DSSpacing.md),
            stackView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -DSSpacing.md)
        ])
    }

    @objc private func retryTapped() {
        onRetry?()
    }
}
#else
public final class ContentStateView {
    public init() {}
    public func render(_ state: ContentState) {}
}
#endif
