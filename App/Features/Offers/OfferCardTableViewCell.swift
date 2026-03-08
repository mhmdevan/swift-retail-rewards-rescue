import DesignSystem
import FeaturesOffers
import SDWebImage
import UIKit

final class OfferCardTableViewCell: UITableViewCell {
    static let reuseIdentifier = "OfferCardTableViewCell"

    var onSaveTapped: (() -> Void)?

    private let cardContainer = UIView()
    private let offerImageView = UIImageView()
    private let titleLabel = UILabel()
    private let subtitleLabel = UILabel()
    private let statusLabel = UILabel()
    private let saveButton = UIButton(type: .system)

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        configureUI()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        configureUI()
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        offerImageView.sd_cancelCurrentImageLoad()
        offerImageView.image = UIImage(systemName: "photo")
        titleLabel.text = nil
        subtitleLabel.text = nil
        statusLabel.text = nil
        onSaveTapped = nil
    }

    func configure(with offer: OfferSummary, formatter: DateFormatter) {
        titleLabel.text = offer.title
        subtitleLabel.text = offer.subtitle

        let status = offer.isExpired ? "Expired" : "Active"
        let saved = offer.isSaved ? "Saved" : "Not saved"
        statusLabel.text = "\(saved) • \(status) • Expires \(formatter.string(from: offer.expiryDate))"
        statusLabel.textColor = offer.isExpired ? .dsDanger : .dsTextSecondary

        let symbolName = offer.isSaved ? "bookmark.fill" : "bookmark"
        saveButton.setImage(UIImage(systemName: symbolName), for: .normal)
        saveButton.tintColor = offer.isSaved ? .systemGreen : .dsAccent
        saveButton.isEnabled = !offer.isExpired
        saveButton.alpha = offer.isExpired ? 0.5 : 1
        saveButton.accessibilityLabel = offer.isSaved ? "Unsave offer" : "Save offer"

        if let imageURL = offer.imageURL {
            offerImageView.sd_setImage(
                with: imageURL,
                placeholderImage: UIImage(systemName: "photo"),
                options: [.retryFailed, .continueInBackground, .highPriority]
            )
        } else {
            offerImageView.image = UIImage(systemName: "tag.fill")
            offerImageView.tintColor = .dsAccent
        }
    }

    private func configureUI() {
        selectionStyle = .none
        backgroundColor = .clear
        contentView.backgroundColor = .clear

        cardContainer.translatesAutoresizingMaskIntoConstraints = false
        cardContainer.backgroundColor = .dsSurface
        cardContainer.layer.cornerRadius = 14
        cardContainer.layer.cornerCurve = .continuous

        offerImageView.translatesAutoresizingMaskIntoConstraints = false
        offerImageView.contentMode = .scaleAspectFill
        offerImageView.clipsToBounds = true
        offerImageView.layer.cornerRadius = 10
        offerImageView.backgroundColor = .systemGray6

        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.font = DSTypography.subtitle()
        titleLabel.textColor = .dsTextPrimary
        titleLabel.numberOfLines = 2

        subtitleLabel.translatesAutoresizingMaskIntoConstraints = false
        subtitleLabel.font = DSTypography.body()
        subtitleLabel.textColor = .dsTextSecondary
        subtitleLabel.numberOfLines = 2

        statusLabel.translatesAutoresizingMaskIntoConstraints = false
        statusLabel.font = DSTypography.caption()
        statusLabel.numberOfLines = 2

        saveButton.translatesAutoresizingMaskIntoConstraints = false
        saveButton.addTarget(self, action: #selector(didTapSaveButton), for: .touchUpInside)

        let contentStack = UIStackView(arrangedSubviews: [titleLabel, subtitleLabel, statusLabel])
        contentStack.axis = .vertical
        contentStack.alignment = .fill
        contentStack.distribution = .fill
        contentStack.spacing = DSSpacing.xs
        contentStack.translatesAutoresizingMaskIntoConstraints = false

        cardContainer.addSubview(offerImageView)
        cardContainer.addSubview(contentStack)
        cardContainer.addSubview(saveButton)
        contentView.addSubview(cardContainer)

        NSLayoutConstraint.activate([
            cardContainer.topAnchor.constraint(equalTo: contentView.topAnchor, constant: DSSpacing.xs),
            cardContainer.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: DSSpacing.md),
            cardContainer.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -DSSpacing.md),
            cardContainer.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -DSSpacing.xs),

            offerImageView.topAnchor.constraint(equalTo: cardContainer.topAnchor, constant: DSSpacing.md),
            offerImageView.leadingAnchor.constraint(equalTo: cardContainer.leadingAnchor, constant: DSSpacing.md),
            offerImageView.bottomAnchor.constraint(lessThanOrEqualTo: cardContainer.bottomAnchor, constant: -DSSpacing.md),
            offerImageView.widthAnchor.constraint(equalToConstant: 86),
            offerImageView.heightAnchor.constraint(equalToConstant: 86),

            saveButton.topAnchor.constraint(equalTo: cardContainer.topAnchor, constant: DSSpacing.sm),
            saveButton.trailingAnchor.constraint(equalTo: cardContainer.trailingAnchor, constant: -DSSpacing.sm),
            saveButton.widthAnchor.constraint(equalToConstant: 30),
            saveButton.heightAnchor.constraint(equalToConstant: 30),

            contentStack.topAnchor.constraint(equalTo: cardContainer.topAnchor, constant: DSSpacing.md),
            contentStack.leadingAnchor.constraint(equalTo: offerImageView.trailingAnchor, constant: DSSpacing.md),
            contentStack.trailingAnchor.constraint(equalTo: saveButton.leadingAnchor, constant: -DSSpacing.sm),
            contentStack.bottomAnchor.constraint(lessThanOrEqualTo: cardContainer.bottomAnchor, constant: -DSSpacing.md)
        ])
    }

    @objc private func didTapSaveButton() {
        onSaveTapped?()
    }
}
