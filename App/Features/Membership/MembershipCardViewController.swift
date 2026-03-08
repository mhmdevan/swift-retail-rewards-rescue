import DesignSystem
import CoreImage.CIFilterBuiltins
import UIKit

final class MembershipCardViewController: UIViewController {
    private let loyaltyBridge: LegacyLoyaltyBridge

    private let cardContainer = UIView()
    private let memberLabel = UILabel()
    private let tierLabel = UILabel()
    private let pointsLabel = UILabel()
    private let payloadTitleLabel = UILabel()
    private let payloadValueLabel = UILabel()
    private let barcodeImageView = UIImageView()
    private let refreshButton = DSButton(frame: .zero)
    private let invalidPayloadButton = UIButton(type: .system)
    private let statusLabel = UILabel()

    private var currentCardData: MembershipCardData?

    init(loyaltyBridge: LegacyLoyaltyBridge = LegacyLoyaltyBridge()) {
        self.loyaltyBridge = loyaltyBridge
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .dsBackground
        configureLayout()
        generateAndRenderCard()
    }

    private func configureLayout() {
        cardContainer.translatesAutoresizingMaskIntoConstraints = false
        cardContainer.backgroundColor = .dsSurface
        cardContainer.layer.cornerRadius = 16

        memberLabel.font = DSTypography.subtitle()
        memberLabel.textColor = .dsTextPrimary

        tierLabel.font = DSTypography.body()
        tierLabel.textColor = .dsTextSecondary

        pointsLabel.font = DSTypography.body()
        pointsLabel.textColor = .dsTextSecondary

        payloadTitleLabel.font = DSTypography.caption()
        payloadTitleLabel.textColor = .dsTextSecondary
        payloadTitleLabel.text = "Barcode Payload"

        payloadValueLabel.font = UIFont.monospacedSystemFont(ofSize: 13, weight: .regular)
        payloadValueLabel.textColor = .dsTextPrimary
        payloadValueLabel.numberOfLines = 0

        barcodeImageView.contentMode = .scaleAspectFit
        barcodeImageView.backgroundColor = .white
        barcodeImageView.layer.cornerRadius = 8
        barcodeImageView.clipsToBounds = true

        refreshButton.setTitle("Refresh Card", for: .normal)
        refreshButton.addTarget(self, action: #selector(didTapRefresh), for: .touchUpInside)

        invalidPayloadButton.setTitle("Simulate Invalid Payload", for: .normal)
        invalidPayloadButton.addTarget(self, action: #selector(didTapInvalidPayload), for: .touchUpInside)

        statusLabel.font = DSTypography.caption()
        statusLabel.textColor = .dsDanger
        statusLabel.numberOfLines = 0
        statusLabel.isHidden = true

        let stack = UIStackView(arrangedSubviews: [
            memberLabel,
            tierLabel,
            pointsLabel,
            payloadTitleLabel,
            payloadValueLabel,
            barcodeImageView,
            refreshButton,
            invalidPayloadButton,
            statusLabel
        ])
        stack.axis = .vertical
        stack.spacing = DSSpacing.sm
        stack.translatesAutoresizingMaskIntoConstraints = false

        view.addSubview(cardContainer)
        cardContainer.addSubview(stack)

        NSLayoutConstraint.activate([
            cardContainer.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: DSSpacing.lg),
            cardContainer.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: DSSpacing.md),
            cardContainer.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -DSSpacing.md),

            stack.topAnchor.constraint(equalTo: cardContainer.topAnchor, constant: DSSpacing.md),
            stack.leadingAnchor.constraint(equalTo: cardContainer.leadingAnchor, constant: DSSpacing.md),
            stack.trailingAnchor.constraint(equalTo: cardContainer.trailingAnchor, constant: -DSSpacing.md),
            stack.bottomAnchor.constraint(equalTo: cardContainer.bottomAnchor, constant: -DSSpacing.md),

            barcodeImageView.heightAnchor.constraint(equalToConstant: 92),
            refreshButton.heightAnchor.constraint(equalToConstant: 46)
        ])
    }

    @objc private func didTapRefresh() {
        generateAndRenderCard()
    }

    @objc private func didTapInvalidPayload() {
        guard let currentCardData else {
            return
        }

        let invalidPayload = currentCardData.barcodePayload + "-invalid"
        if loyaltyBridge.parseMemberID(from: invalidPayload) == nil {
            statusLabel.text = "Invalid payload detected. Please refresh the card."
            statusLabel.isHidden = false
        }
    }

    private func generateAndRenderCard() {
        statusLabel.isHidden = true

        do {
            let points = Int.random(in: 1200 ... 4000)
            let cardData = try loyaltyBridge.generateMembershipCard(
                memberID: "MEM-102938",
                tierName: "Gold",
                pointsBalance: points
            )
            currentCardData = cardData

            memberLabel.text = "Member ID: \(cardData.memberID)"
            tierLabel.text = "Tier: \(cardData.tierName)"
            pointsLabel.text = "Points: \(cardData.pointsBalance)"
            payloadValueLabel.text = cardData.barcodePayload
            renderBarcode(for: cardData.barcodePayload)
        } catch {
            currentCardData = nil
            memberLabel.text = "Member ID: --"
            tierLabel.text = "Tier: --"
            pointsLabel.text = "Points: --"
            payloadValueLabel.text = "--"
            barcodeImageView.image = nil
            statusLabel.text = error.localizedDescription
            statusLabel.isHidden = false
        }
    }

    private func renderBarcode(for payload: String) {
        let filter = CIFilter.code128BarcodeGenerator()
        filter.message = Data(payload.utf8)
        filter.quietSpace = 7

        guard let outputImage = filter.outputImage else {
            barcodeImageView.image = nil
            return
        }

        let transform = CGAffineTransform(scaleX: 3.0, y: 3.0)
        let scaledImage = outputImage.transformed(by: transform)
        let context = CIContext()
        guard let cgImage = context.createCGImage(scaledImage, from: scaledImage.extent) else {
            barcodeImageView.image = nil
            return
        }

        barcodeImageView.image = UIImage(cgImage: cgImage)
    }
}
