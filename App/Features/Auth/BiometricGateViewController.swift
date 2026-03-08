import Core
import DesignSystem
import UIKit

final class BiometricGateViewController: UIViewController {
    var onAuthenticate: (() async -> BiometricAuthenticationResult)?
    var onUnlockSucceeded: (() -> Void)?
    var onFallbackToPassword: (() -> Void)?

    private let biometricType: BiometricType
    private let decisionEngine: BiometricGateDecisionEngine

    private let iconView = UIImageView()
    private let titleLabel = UILabel()
    private let subtitleLabel = UILabel()
    private let statusLabel = UILabel()
    private let retryButton = DSButton(frame: .zero)
    private let fallbackButton = UIButton(type: .system)
    private let activityIndicator = UIActivityIndicatorView(style: .large)
    private let stackView = UIStackView()

    private var hasAutoAttempted = false
    private var unlockTask: Task<Void, Never>?

    init(
        biometricType: BiometricType,
        decisionEngine: BiometricGateDecisionEngine = .init()
    ) {
        self.biometricType = biometricType
        self.decisionEngine = decisionEngine
        super.init(nibName: nil, bundle: nil)
        title = "Unlock"
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    deinit {
        unlockTask?.cancel()
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .dsBackground
        configureLayout()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        if !hasAutoAttempted {
            hasAutoAttempted = true
            startAuthentication()
        }
    }

    private func configureLayout() {
        iconView.image = UIImage(systemName: iconName(for: biometricType))
        iconView.tintColor = .dsAccent
        iconView.preferredSymbolConfiguration = UIImage.SymbolConfiguration(pointSize: 54, weight: .medium)

        titleLabel.text = "Biometric unlock required"
        titleLabel.font = DSTypography.title()
        titleLabel.textColor = .dsTextPrimary
        titleLabel.numberOfLines = 0
        titleLabel.textAlignment = .center

        subtitleLabel.text = subtitleText(for: biometricType)
        subtitleLabel.font = DSTypography.body()
        subtitleLabel.textColor = .dsTextSecondary
        subtitleLabel.numberOfLines = 0
        subtitleLabel.textAlignment = .center

        statusLabel.font = DSTypography.caption()
        statusLabel.textColor = .dsDanger
        statusLabel.numberOfLines = 0
        statusLabel.textAlignment = .center
        statusLabel.isHidden = true

        retryButton.setTitle("Try Again", for: .normal)
        retryButton.addTarget(self, action: #selector(didTapRetry), for: .touchUpInside)

        fallbackButton.setTitle("Use Password Instead", for: .normal)
        fallbackButton.setTitleColor(.dsTextSecondary, for: .normal)
        fallbackButton.titleLabel?.font = DSTypography.body()
        fallbackButton.addTarget(self, action: #selector(didTapFallback), for: .touchUpInside)

        activityIndicator.color = .dsAccent

        stackView.axis = .vertical
        stackView.alignment = .center
        stackView.spacing = DSSpacing.md
        stackView.translatesAutoresizingMaskIntoConstraints = false

        [iconView, titleLabel, subtitleLabel, activityIndicator, statusLabel, retryButton, fallbackButton]
            .forEach { stackView.addArrangedSubview($0) }

        view.addSubview(stackView)

        NSLayoutConstraint.activate([
            stackView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: DSSpacing.lg),
            stackView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -DSSpacing.lg),
            stackView.centerYAnchor.constraint(equalTo: view.safeAreaLayoutGuide.centerYAnchor),
            retryButton.heightAnchor.constraint(equalToConstant: 46),
            retryButton.widthAnchor.constraint(greaterThanOrEqualToConstant: 180)
        ])
    }

    @objc private func didTapRetry() {
        startAuthentication()
    }

    @objc private func didTapFallback() {
        onFallbackToPassword?()
    }

    private func startAuthentication() {
        unlockTask?.cancel()
        setLoading(true)
        statusLabel.isHidden = true

        unlockTask = Task { [weak self] in
            guard let self else {
                return
            }

            let result = await (self.onAuthenticate?() ?? .failed(message: "Unlock service is unavailable."))
            if Task.isCancelled {
                return
            }

            await MainActor.run {
                self.handleAuthenticationResult(result)
            }
        }
    }

    private func handleAuthenticationResult(_ result: BiometricAuthenticationResult) {
        let action = decisionEngine.action(for: result)

        switch action {
        case .proceedToMainShell:
            setLoading(false)
            onUnlockSucceeded?()

        case let .allowRetry(message):
            setLoading(false)
            renderError(message)

        case let .fallbackToPassword(message):
            setLoading(false)
            renderError(message)
            retryButton.isHidden = true
        }
    }

    private func setLoading(_ loading: Bool) {
        retryButton.isEnabled = !loading
        fallbackButton.isEnabled = !loading

        if loading {
            retryButton.isHidden = true
            activityIndicator.startAnimating()
        } else {
            retryButton.isHidden = false
            activityIndicator.stopAnimating()
        }
    }

    private func renderError(_ message: String) {
        statusLabel.text = message
        statusLabel.isHidden = false
    }

    private func subtitleText(for type: BiometricType) -> String {
        switch type {
        case .faceID:
            return "Confirm with Face ID to open your account."
        case .touchID:
            return "Confirm with Touch ID to open your account."
        case .opticID:
            return "Confirm with Optic ID to open your account."
        case .unknown:
            return "Confirm your identity to continue."
        }
    }

    private func iconName(for type: BiometricType) -> String {
        switch type {
        case .faceID:
            return "faceid"
        case .touchID:
            return "touchid"
        case .opticID:
            return "opticid"
        case .unknown:
            return "person.badge.key.fill"
        }
    }
}
