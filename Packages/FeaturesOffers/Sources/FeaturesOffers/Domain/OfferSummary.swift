import Foundation

public struct OfferSummary: Equatable, Sendable {
    public let id: String
    public let title: String
    public let subtitle: String
    public let imageURL: URL?
    public let expiryDate: Date
    public let isSaved: Bool
    public let isExpired: Bool

    public init(
        id: String,
        title: String,
        subtitle: String,
        imageURL: URL?,
        expiryDate: Date,
        isSaved: Bool = false,
        isExpired: Bool = false
    ) {
        self.id = id
        self.title = title
        self.subtitle = subtitle
        self.imageURL = imageURL
        self.expiryDate = expiryDate
        self.isSaved = isSaved
        self.isExpired = isExpired
    }
}
