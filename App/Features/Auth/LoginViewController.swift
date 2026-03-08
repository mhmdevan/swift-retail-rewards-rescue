import Core
import DesignSystem
import UIKit

struct LoginSubmissionInput {
    let email: String
    let password: String
    let biometricEnabled: Bool
}

final class LoginViewController: UIViewController {
    enum StatusTone {
        case info
        case error
    }

    var onSubmit: ((LoginSubmissionInput) async -> Result<Void, String>)?

    private let validator: any LoginFormValidating
    private let initialStatusMessage: String?
    private let initialStatusTone: StatusTone

    private let emailField = UITextField()
    private let passwordField = UITextField()
    private let biometricLabel = UILabel()
    private let biometricSwitch = UISwitch()
    private let submitButton = DSButton(frame: .zero)
    private let loadingIndicator = UIActivityIndicatorView(style: .medium)
    private let statusLabel = UILabel()
    private let stackView = UIStackView()
    private var loginTask: Task<Void, Never>?

    init(
        validator: any LoginFormValidating = LoginFormValidator(),
        initialStatusMessage: String? = nil,
        initialStatusTone: StatusTone = .info
    ) {
        self.validator = validator
        self.initialStatusMessage = initialStatusMessage
        self.initialStatusTone = initialStatusTone
        super.init(nibName: "LoginViewController", bundle: .main)
        title = "Sign In"
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    deinit {
        loginTask?.cancel()
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .dsBackground
        configureForm()

        if let initialStatusMessage {
            renderStatus(initialStatusMessage, tone: initialStatusTone)
        }
    }

    private func configureForm() {
        emailField.placeholder = "Email"
        emailField.keyboardType = .emailAddress
        emailField.autocapitalizationType = .none
        emailField.autocorrectionType = .no
        emailField.borderStyle = .roundedRect
        emailField.textContentType = .username
        emailField.accessibilityIdentifier = "login_email"

        passwordField.placeholder = "Password"
        passwordField.isSecureTextEntry = true
        passwordField.borderStyle = .roundedRect
        passwordField.textContentType = .password
        passwordField.accessibilityIdentifier = "login_password"

        biometricLabel.text = "Use biometric unlock for next launches"
        biometricLabel.font = DSTypography.body()
        biometricLabel.textColor = .dsTextPrimary
        biometricLabel.numberOfLines = 0

        biometricSwitch.isOn = true
        biometricSwitch.accessibilityIdentifier = "login_biometrics_toggle"

        let biometricStack = UIStackView(arrangedSubviews: [biometricLabel, biometricSwitch])
        biometricStack.axis = .horizontal
        biometricStack.alignment = .center
        biometricStack.spacing = DSSpacing.sm

        submitButton.setTitle("Sign In", for: .normal)
        submitButton.accessibilityIdentifier = "login_submit"
        submitButton.addTarget(self, action: #selector(didTapSubmit), for: .touchUpInside)

        loadingIndicator.hidesWhenStopped = true
        loadingIndicator.color = .dsAccent

        statusLabel.font = DSTypography.caption()
        statusLabel.numberOfLines = 0
        statusLabel.textAlignment = .center
        statusLabel.isHidden = true

        stackView.axis = .vertical
        stackView.spacing = DSSpacing.md
        stackView.translatesAutoresizingMaskIntoConstraints = false

        [emailField, passwordField, biometricStack, submitButton, loadingIndicator, statusLabel]
            .forEach { stackView.addArrangedSubview($0) }

        view.addSubview(stackView)

        NSLayoutConstraint.activate([
            stackView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: DSSpacing.md),
            stackView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -DSSpacing.md),
            stackView.centerYAnchor.constraint(equalTo: view.safeAreaLayoutGuide.centerYAnchor),
            submitButton.heightAnchor.constraint(equalToConstant: 48)
        ])

        emailField.text = "demo@retailrescue.app"
        passwordField.text = "password123"
    }

    @objc private func didTapSubmit() {
        loginTask?.cancel()
        clearStatus()

        let email = emailField.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let password = passwordField.text ?? ""

        if let validationError = validator.validate(email: email, password: password) {
            renderStatus(validationError.localizedDescription, tone: .error)
            return
        }

        let input = LoginSubmissionInput(
            email: email,
            password: password,
            biometricEnabled: biometricSwitch.isOn
        )

        setLoading(true)

        loginTask = Task { [weak self] in
            guard let self else {
                return
            }

            let result = await (self.onSubmit?(input) ?? .failure("Login handler is not configured."))

            if Task.isCancelled {
                return
            }

            await MainActor.run {
                self.handleSubmissionResult(result)
            }
        }
    }

    private func handleSubmissionResult(_ result: Result<Void, String>) {
        switch result {
        case .success:
            break
        case let .failure(message):
            setLoading(false)
            renderStatus(message, tone: .error)
        }
    }

    private func setLoading(_ isLoading: Bool) {
        submitButton.isEnabled = !isLoading
        emailField.isEnabled = !isLoading
        passwordField.isEnabled = !isLoading
        biometricSwitch.isEnabled = !isLoading

        if isLoading {
            loadingIndicator.startAnimating()
        } else {
            loadingIndicator.stopAnimating()
        }
    }

    private func clearStatus() {
        statusLabel.text = nil
        statusLabel.isHidden = true
    }

    private func renderStatus(_ message: String, tone: StatusTone) {
        statusLabel.textColor = tone == .error ? .dsDanger : .dsTextSecondary
        statusLabel.text = message
        statusLabel.isHidden = false
    }
}
