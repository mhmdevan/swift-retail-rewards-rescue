import XCTest
@testable import RetailRewardsRescue

final class LegacyLoyaltyBridgeTests: XCTestCase {
    func testGenerateMembershipCardProducesValidatedPayload() throws {
        let sut = LegacyLoyaltyBridge()

        let card = try sut.generateMembershipCard(
            memberID: "MEM-1234",
            tierName: "Gold",
            pointsBalance: 520
        )

        XCTAssertEqual(card.memberID, "MEM-1234")
        XCTAssertEqual(sut.parseMemberID(from: card.barcodePayload), "MEM-1234")
    }

    func testParseMemberIDReturnsNilForMalformedPayload() {
        let sut = LegacyLoyaltyBridge()

        let parsed = sut.parseMemberID(from: "invalid-payload")

        XCTAssertNil(parsed)
    }
}
