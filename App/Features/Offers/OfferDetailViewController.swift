import DesignSystem
import FeaturesOffers
import Foundation
import SDWebImage
import UIKit

final class OfferDetailViewController: UIViewController {
    var onSaveStateChanged: ((OfferSummary) -> Void)?

    private let saveService: OfferSaveService
    private var offer: OfferSummary

    private let scrollView = UIScrollView()
    private let contentView = UIView()
    private let imageView = UIImageView()
    private let titleLabel = UILabel()
    private let subtitleLabel = UILabel()
    private let expiryLabel = UILabel()
    private let termsLabel = UILabel()
    private let saveButton = DSButton(frame: .zero)
    private let statusLabel = UILabel()

    init(offer: OfferSummary, saveService: OfferSaveService) {
        self.offer = offer
        self.saveService = saveService
        super.init(nibName: nil, bundle: nil)
        title = "Offer Detail"
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .dsBackground
        configureLayout()
        renderOffer()
    }

    private func configureLayout() {
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        contentView.translatesAutoresizingMaskIntoConstraints = false

        view.addSubview(scrollView)
        scrollView.addSubview(contentView)

        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),

            contentView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            contentView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            contentView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            contentView.widthAnchor.constraint(equalTo: scrollView.widthAnchor)
        ])

        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        imageView.backgroundColor = .dsSurface
        imageView.layer.cornerRadius = 14

        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.font = DSTypography.title()
        titleLabel.textColor = .dsTextPrimary
        titleLabel.numberOfLines = 0

        subtitleLabel.translatesAutoresizingMaskIntoConstraints = false
        subtitleLabel.font = DSTypography.subtitle()
        subtitleLabel.textColor = .dsTextSecondary
        subtitleLabel.numberOfLines = 0

        expiryLabel.translatesAutoresizingMaskIntoConstraints = false
        expiryLabel.font = DSTypography.body()
        expiryLabel.numberOfLines = 0

        termsLabel.translatesAutoresizingMaskIntoConstraints = false
        termsLabel.font = DSTypography.body()
        termsLabel.textColor = .dsTextSecondary
        termsLabel.numberOfLines = 0
        termsLabel.text = "Terms: This is a demo offer detail generated for legacy-to-modern migration simulation."

        saveButton.translatesAutoresizingMaskIntoConstraints = false
        saveButton.accessibilityIdentifier = "offer_detail_save_button"
        saveButton.addTarget(self, action: #selector(didTapSave), for: .touchUpInside)

        statusLabel.translatesAutoresizingMaskIntoConstraints = false
        statusLabel.font = DSTypography.caption()
        statusLabel.numberOfLines = 0
        statusLabel.textColor = .dsDanger
        statusLabel.isHidden = true

        [imageView, titleLabel, subtitleLabel, expiryLabel, termsLabel, saveButton, statusLabel].forEach {
            contentView.addSubview($0)
        }

        NSLayoutConstraint.activate([
            imageView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: DSSpacing.md),
            imageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: DSSpacing.md),
            imageView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -DSSpacing.md),
            imageView.heightAnchor.constraint(equalToConstant: 210),

            titleLabel.topAnchor.constraint(equalTo: imageView.bottomAnchor, constant: DSSpacing.md),
            titleLabel.leadingAnchor.constraint(equalTo: imageView.leadingAnchor),
            titleLabel.trailingAnchor.constraint(equalTo: imageView.trailingAnchor),

            subtitleLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: DSSpacing.xs),
            subtitleLabel.leadingAnchor.constraint(equalTo: titleLabel.leadingAnchor),
            subtitleLabel.trailingAnchor.constraint(equalTo: titleLabel.trailingAnchor),

            expiryLabel.topAnchor.constraint(equalTo: subtitleLabel.bottomAnchor, constant: DSSpacing.xs),
            expiryLabel.leadingAnchor.constraint(equalTo: subtitleLabel.leadingAnchor),
            expiryLabel.trailingAnchor.constraint(equalTo: subtitleLabel.trailingAnchor),

            termsLabel.topAnchor.constraint(equalTo: expiryLabel.bottomAnchor, constant: DSSpacing.md),
            termsLabel.leadingAnchor.constraint(equalTo: expiryLabel.leadingAnchor),
            termsLabel.trailingAnchor.constraint(equalTo: expiryLabel.trailingAnchor),

            saveButton.topAnchor.constraint(equalTo: termsLabel.bottomAnchor, constant: DSSpacing.lg),
            saveButton.leadingAnchor.constraint(equalTo: termsLabel.leadingAnchor),
            saveButton.trailingAnchor.constraint(equalTo: termsLabel.trailingAnchor),
            saveButton.heightAnchor.constraint(equalToConstant: 48),

            statusLabel.topAnchor.constraint(equalTo: saveButton.bottomAnchor, constant: DSSpacing.xs),
            statusLabel.leadingAnchor.constraint(equalTo: saveButton.leadingAnchor),
            statusLabel.trailingAnchor.constraint(equalTo: saveButton.trailingAnchor),
            statusLabel.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -DSSpacing.lg)
        ])
    }

    @objc private func didTapSave() {
        do {
            offer = try saveService.toggleSave(for: offer)
            statusLabel.isHidden = true
            renderOffer()
            onSaveStateChanged?(offer)
        } catch {
            SentryCrashReporter.shared.captureNonFatal(
                error,
                context: [
                    "feature": "offer_detail",
                    "offer_id": offer.id
                ]
            )
            statusLabel.text = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
            statusLabel.isHidden = false
        }
    }

    private func renderOffer() {
        let normalized = saveService.applySavedAndExpiryState(to: offer)
        offer = normalized

        titleLabel.text = offer.title
        subtitleLabel.text = offer.subtitle

        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        let statusText = offer.isExpired ? "Expired" : "Active"
        expiryLabel.text = "Status: \(statusText) • Expires \(formatter.string(from: offer.expiryDate))"
        expiryLabel.textColor = offer.isExpired ? .dsDanger : .dsTextSecondary

        let buttonTitle: String
        if offer.isExpired {
            buttonTitle = "Expired"
            saveButton.isEnabled = false
            saveButton.alpha = 0.6
        } else {
            buttonTitle = offer.isSaved ? "Unsave Offer" : "Save Offer"
            saveButton.isEnabled = true
            saveButton.alpha = 1
        }
        saveButton.setTitle(buttonTitle, for: .normal)

        if let imageURL = offer.imageURL {
            imageView.sd_setImage(with: imageURL, placeholderImage: UIImage(systemName: "photo"))
        } else {
            imageView.image = UIImage(systemName: "tag.fill")
            imageView.tintColor = .dsAccent
        }
    }
}
