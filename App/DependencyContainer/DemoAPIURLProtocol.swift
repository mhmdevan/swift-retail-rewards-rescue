import Foundation

final class DemoAPIURLProtocol: URLProtocol {
    override class func canInit(with request: URLRequest) -> Bool {
        guard let host = request.url?.host?.lowercased() else {
            return false
        }

        return host == "legacy.retailrewardsrescue.local" || host == "modern.retailrewardsrescue.local"
    }

    override class func canonicalRequest(for request: URLRequest) -> URLRequest {
        request
    }

    override func startLoading() {
        guard let url = request.url else {
            sendErrorResponse("Invalid URL")
            return
        }

        do {
            let payload = try payloadForRequest(url: url)
            let response = HTTPURLResponse(
                url: url,
                statusCode: payload.statusCode,
                httpVersion: nil,
                headerFields: ["Content-Type": "application/json"]
            )!

            client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
            client?.urlProtocol(self, didLoad: payload.data)
            client?.urlProtocolDidFinishLoading(self)
        } catch {
            sendErrorResponse(error.localizedDescription)
        }
    }

    override func stopLoading() {}

    private func payloadForRequest(url: URL) throws -> (statusCode: Int, data: Data) {
        let components = URLComponents(url: url, resolvingAgainstBaseURL: false)
        let page = Int(components?.queryItems?.first(where: { $0.name == "page" })?.value ?? "1") ?? 1
        let pageSize = Int(components?.queryItems?.first(where: { $0.name == "pageSize" })?.value ?? "20") ?? 20

        if url.path == "/legacy/v1/offers" {
            return (200, try makeLegacyPayload(page: page, pageSize: pageSize))
        }

        if url.path == "/modern/v1/offers" {
            return (200, try makeModernPayload(page: page, pageSize: pageSize))
        }

        return (404, Data("{\"message\":\"Not found\"}".utf8))
    }

    private func makeLegacyPayload(page: Int, pageSize: Int) throws -> Data {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601

        let envelope = LegacyEnvelope(offers: makeOffers(page: page, pageSize: pageSize, prefix: "legacy"))
        return try encoder.encode(envelope)
    }

    private func makeModernPayload(page: Int, pageSize: Int) throws -> Data {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601

        let envelope = ModernEnvelope(items: makeOffers(page: page, pageSize: pageSize, prefix: "modern"))
        return try encoder.encode(envelope)
    }

    private func makeOffers(page: Int, pageSize: Int, prefix: String) -> [DemoOffer] {
        guard page <= 2 else {
            return []
        }

        let count = min(pageSize, 5)
        return (0 ..< count).map { index in
            DemoOffer(
                id: "\(prefix)-offer-\(page)-\(index)",
                title: "\(prefix.capitalized) Offer \(index + 1)",
                subtitle: "Page \(page) reward for loyalty members",
                imageURL: URL(string: "https://images.retailrewardsrescue.local/\(prefix)-\(index).png"),
                expiryDate: Date(timeIntervalSince1970: 1_798_675_200 + Double(index * 86_400))
            )
        }
    }

    private func sendErrorResponse(_ message: String) {
        client?.urlProtocol(self, didFailWithError: URLError(.cannotLoadFromNetwork, userInfo: [NSLocalizedDescriptionKey: message]))
    }
}

private struct LegacyEnvelope: Encodable {
    let offers: [DemoOffer]
}

private struct ModernEnvelope: Encodable {
    let items: [DemoOffer]
}

private struct DemoOffer: Encodable {
    let id: String
    let title: String
    let subtitle: String
    let imageURL: URL?
    let expiryDate: Date

    enum CodingKeys: String, CodingKey {
        case id
        case title
        case subtitle
        case imageURL = "image_url"
        case expiryDate = "expiry_date"
    }
}
