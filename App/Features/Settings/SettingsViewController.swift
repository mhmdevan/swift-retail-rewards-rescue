import DesignSystem
import UIKit

final class SettingsViewController: UIViewController {
    var onLogoutRequested: (() -> Void)?
    var onDiagnosticsRequested: (() -> Void)?

    private let titleLabel = UILabel()
    private let descriptionLabel = UILabel()
    private let diagnosticsButton = UIButton(type: .system)
    private let logoutButton = DSButton(frame: .zero)
    private let stackView = UIStackView()

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .dsBackground
        title = "Settings"
        configureLayout()
    }

    private func configureLayout() {
        titleLabel.text = "Session"
        titleLabel.font = DSTypography.title()
        titleLabel.textColor = .dsTextPrimary

        descriptionLabel.text = "Log out clears persisted session and returns to sign in. Diagnostics helps validate routes/background refresh/logging."
        descriptionLabel.font = DSTypography.body()
        descriptionLabel.textColor = .dsTextSecondary
        descriptionLabel.numberOfLines = 0

        diagnosticsButton.setTitle("Open Diagnostics", for: .normal)
        diagnosticsButton.titleLabel?.font = DSTypography.body()
        diagnosticsButton.addTarget(self, action: #selector(didTapDiagnostics), for: .touchUpInside)

        logoutButton.setTitle("Log Out", for: .normal)
        logoutButton.accessibilityIdentifier = "settings_logout"
        logoutButton.addTarget(self, action: #selector(didTapLogout), for: .touchUpInside)

        stackView.axis = .vertical
        stackView.spacing = DSSpacing.md
        stackView.translatesAutoresizingMaskIntoConstraints = false

        [titleLabel, descriptionLabel, diagnosticsButton, logoutButton].forEach { stackView.addArrangedSubview($0) }

        view.addSubview(stackView)

        NSLayoutConstraint.activate([
            stackView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: DSSpacing.md),
            stackView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -DSSpacing.md),
            stackView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: DSSpacing.lg),
            logoutButton.heightAnchor.constraint(equalToConstant: 46)
        ])
    }

    @objc private func didTapDiagnostics() {
        onDiagnosticsRequested?()
    }

    @objc private func didTapLogout() {
        onLogoutRequested?()
    }
}
