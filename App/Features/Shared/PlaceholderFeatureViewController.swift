import DesignSystem
import UIKit

class PlaceholderFeatureViewController: UIViewController {
    private let titleText: String
    private let descriptionText: String

    private let stateContainer = ListStateContainerView()
    private let iconView = UIImageView()
    private let titleLabel = UILabel()
    private let descriptionLabel = UILabel()
    private let actionButton = DSButton(frame: .zero)
    private let contentStack = UIStackView()

    init(titleText: String, descriptionText: String, actionTitle: String = "Refresh") {
        self.titleText = titleText
        self.descriptionText = descriptionText
        super.init(nibName: nil, bundle: nil)
        actionButton.setTitle(actionTitle, for: .normal)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func loadView() {
        view = stateContainer
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        configureContent()
    }

    func renderInitialState() {
        stateContainer.setState(.content)
    }

    private func configureContent() {
        iconView.image = UIImage(systemName: "square.grid.2x2")
        iconView.tintColor = .dsAccent
        iconView.preferredSymbolConfiguration = UIImage.SymbolConfiguration(pointSize: 42, weight: .medium)

        titleLabel.text = titleText
        titleLabel.font = DSTypography.title()
        titleLabel.textColor = .dsTextPrimary
        titleLabel.numberOfLines = 0
        titleLabel.textAlignment = .center

        descriptionLabel.text = descriptionText
        descriptionLabel.font = DSTypography.body()
        descriptionLabel.textColor = .dsTextSecondary
        descriptionLabel.numberOfLines = 0
        descriptionLabel.textAlignment = .center

        actionButton.addTarget(self, action: #selector(handleActionTap), for: .touchUpInside)
        actionButton.setTitleColor(.white, for: .normal)

        contentStack.axis = .vertical
        contentStack.alignment = .center
        contentStack.spacing = DSSpacing.md
        contentStack.translatesAutoresizingMaskIntoConstraints = false

        [iconView, titleLabel, descriptionLabel, actionButton].forEach { contentStack.addArrangedSubview($0) }

        stateContainer.contentView.addSubview(contentStack)

        NSLayoutConstraint.activate([
            contentStack.leadingAnchor.constraint(equalTo: stateContainer.contentView.leadingAnchor, constant: DSSpacing.lg),
            contentStack.trailingAnchor.constraint(equalTo: stateContainer.contentView.trailingAnchor, constant: -DSSpacing.lg),
            contentStack.centerYAnchor.constraint(equalTo: stateContainer.contentView.centerYAnchor),
            actionButton.heightAnchor.constraint(equalToConstant: 46),
            actionButton.widthAnchor.constraint(greaterThanOrEqualToConstant: 160)
        ])

        renderInitialState()
    }

    @objc private func handleActionTap() {
        stateContainer.setState(.loading(message: "Refreshing..."))

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) { [weak self] in
            self?.stateContainer.setState(.content)
        }
    }
}
