import Testing
@testable import Core

@Test func serverErrorDescriptionIncludesStatusCode() {
    let error = AppNetworkError.server(statusCode: 503)

    #expect(error.localizedDescription.contains("503"))
}

@Test func connectivityHasUserFriendlyDescription() {
    let error = AppNetworkError.connectivity

    #expect(error.localizedDescription.contains("internet"))
}
