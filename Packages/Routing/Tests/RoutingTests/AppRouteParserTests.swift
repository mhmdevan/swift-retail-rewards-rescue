import Foundation
import Testing
@testable import Routing

@Test func parseCustomSchemeOffers() {
    let sut = AppRouteParser()

    let route = sut.parse(url: URL(string: "retailrescue://offers")!)

    #expect(route == .offers)
}

@Test func parseCustomSchemeOfferDetail() {
    let sut = AppRouteParser()

    let route = sut.parse(url: URL(string: "retailrescue://offers/detail/offer-123")!)

    #expect(route == .offerDetail(id: "offer-123"))
}

@Test func parseUniversalLinkInboxMessage() {
    let sut = AppRouteParser()

    let route = sut.parse(url: URL(string: "https://retailrewardsrescue.app/inbox/message/msg-9")!)

    #expect(route == .inboxMessage(id: "msg-9"))
}

@Test func parseInvalidHostReturnsNil() {
    let sut = AppRouteParser()

    let route = sut.parse(url: URL(string: "https://example.com/inbox")!)

    #expect(route == nil)
}

@Test func parseCustomSchemeWallet() {
    let sut = AppRouteParser()

    let route = sut.parse(url: URL(string: "retailrescue://wallet")!)

    #expect(route == .wallet)
}

@Test func parseCustomSchemeMalformedOfferDetailReturnsOffersRoot() {
    let sut = AppRouteParser()

    let route = sut.parse(url: URL(string: "retailrescue://offers/detail")!)

    #expect(route == .offers)
}

@Test func parseUniversalLinkInvalidPathReturnsNil() {
    let sut = AppRouteParser()

    let route = sut.parse(url: URL(string: "https://retailrewardsrescue.app/not-supported/path")!)

    #expect(route == nil)
}
