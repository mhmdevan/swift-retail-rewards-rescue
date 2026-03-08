import Foundation

struct MembershipCardData {
    let memberID: String
    let tierName: String
    let pointsBalance: Int
    let barcodePayload: String
}

enum LegacyLoyaltyBridgeError: LocalizedError {
    case generationFailed(String)
    case payloadValidationFailed

    var errorDescription: String? {
        switch self {
        case let .generationFailed(message):
            return message
        case .payloadValidationFailed:
            return "Generated barcode payload is invalid."
        }
    }
}

final class LegacyLoyaltyBridge {
    func generateMembershipCard(
        memberID: String,
        tierName: String,
        pointsBalance: Int
    ) throws -> MembershipCardData {
        var generationError: NSError?
        guard let payload = LegacyLoyaltyBarcodeFormatter.barcodePayload(
            memberID: memberID,
            tier: tierName,
            points: pointsBalance,
            error: &generationError
        ) else {
            throw LegacyLoyaltyBridgeError.generationFailed(
                generationError?.localizedDescription ?? "Unknown barcode generation failure."
            )
        }

        guard LegacyLoyaltyBarcodeFormatter.memberID(payload: payload) == memberID else {
            throw LegacyLoyaltyBridgeError.payloadValidationFailed
        }

        return MembershipCardData(
            memberID: memberID,
            tierName: tierName,
            pointsBalance: pointsBalance,
            barcodePayload: payload
        )
    }

    func parseMemberID(from payload: String) -> String? {
        LegacyLoyaltyBarcodeFormatter.memberID(payload: payload)
    }
}
