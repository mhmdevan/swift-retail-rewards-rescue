import DesignSystem
import Persistence
import Routing
import UIKit

final class MessageDetailViewController: UIViewController {
    var onRouteOpenRequested: ((String) -> Void)?

    private let message: InboxMessage
    private let routeParser = AppRouteParser()
    private let stack = UIStackView()
    private let routeButton = UIButton(type: .system)
    private let routeHintLabel = UILabel()

    init(message: InboxMessage) {
        self.message = message
        super.init(nibName: nil, bundle: nil)
        title = "Message"
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .dsBackground

        let titleLabel = UILabel()
        titleLabel.font = DSTypography.title()
        titleLabel.textColor = .dsTextPrimary
        titleLabel.numberOfLines = 0
        titleLabel.text = message.title

        let bodyLabel = UILabel()
        bodyLabel.font = DSTypography.body()
        bodyLabel.textColor = .dsTextSecondary
        bodyLabel.numberOfLines = 0
        bodyLabel.text = message.body

        let timeLabel = UILabel()
        timeLabel.font = DSTypography.caption()
        timeLabel.textColor = .dsTextSecondary
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        timeLabel.text = formatter.string(from: message.sentAt)

        routeButton.setTitle("Open Related Screen", for: .normal)
        routeButton.addTarget(self, action: #selector(didTapRouteButton), for: .touchUpInside)

        routeHintLabel.font = DSTypography.caption()
        routeHintLabel.textColor = .dsTextSecondary
        routeHintLabel.numberOfLines = 0

        stack.arrangedSubviews.forEach { $0.removeFromSuperview() }
        stack.addArrangedSubview(titleLabel)
        stack.addArrangedSubview(timeLabel)
        stack.addArrangedSubview(bodyLabel)
        stack.addArrangedSubview(routeButton)
        stack.addArrangedSubview(routeHintLabel)
        stack.axis = .vertical
        stack.spacing = DSSpacing.md
        stack.translatesAutoresizingMaskIntoConstraints = false

        view.addSubview(stack)
        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: DSSpacing.lg),
            stack.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: DSSpacing.md),
            stack.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -DSSpacing.md)
        ])

        configureRoutePresentation()
    }

    private func configureRoutePresentation() {
        guard let deepLink = message.deepLink, let url = URL(string: deepLink) else {
            routeButton.isHidden = true
            routeHintLabel.text = "No route attached to this message."
            return
        }

        if routeParser.parse(url: url) != nil {
            routeButton.isHidden = false
            routeHintLabel.text = "This message contains a valid route."
        } else {
            routeButton.isHidden = true
            routeHintLabel.text = "Route data is malformed and cannot be opened."
        }
    }

    @objc private func didTapRouteButton() {
        guard
            let deepLink = message.deepLink,
            let url = URL(string: deepLink),
            routeParser.parse(url: url) != nil
        else {
            routeHintLabel.text = "Route is invalid."
            return
        }

        onRouteOpenRequested?(deepLink)
    }
}
