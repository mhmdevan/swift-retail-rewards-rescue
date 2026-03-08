import Foundation

public struct AppRouteParser {
    public init() {}

    public func parse(url: URL) -> AppRoute? {
        let components = URLComponents(url: url, resolvingAgainstBaseURL: false)
        let host = components?.host?.lowercased()

        if url.scheme?.lowercased() == "retailrescue" {
            return parseSegments([host].compactMap { $0 } + url.pathComponents.filter { $0 != "/" })
        }

        if url.scheme?.hasPrefix("http") == true,
           host == "retailrewardsrescue.app" {
            return parseSegments(url.pathComponents.filter { $0 != "/" })
        }

        return nil
    }

    private func parseSegments(_ segments: [String]) -> AppRoute? {
        guard let first = segments.first?.lowercased() else { return nil }

        switch first {
        case "offers":
            if segments.count >= 3, segments[1].lowercased() == "detail" {
                return .offerDetail(id: segments[2])
            }
            return .offers
        case "inbox":
            if segments.count >= 3, segments[1].lowercased() == "message" {
                return .inboxMessage(id: segments[2])
            }
            return .inbox
        case "wallet":
            return .wallet
        default:
            return nil
        }
    }
}
