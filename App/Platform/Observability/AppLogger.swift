import Foundation
import OSLog

enum LogCategory: String {
    case app
    case auth
    case offers
    case inbox
    case membership
    case background
    case routing
}

final class AppLogger {
    static let shared = AppLogger()

    private init() {}

    func info(
        _ message: String,
        category: LogCategory,
        metadata: [String: String] = [:],
        redactedKeys: Set<String> = []
    ) {
        write(level: .info, message: message, category: category, metadata: metadata, redactedKeys: redactedKeys)
    }

    func debug(
        _ message: String,
        category: LogCategory,
        metadata: [String: String] = [:],
        redactedKeys: Set<String> = []
    ) {
        #if DEBUG
        write(level: .debug, message: message, category: category, metadata: metadata, redactedKeys: redactedKeys)
        #endif
    }

    func error(
        _ message: String,
        category: LogCategory,
        metadata: [String: String] = [:],
        redactedKeys: Set<String> = []
    ) {
        write(level: .error, message: message, category: category, metadata: metadata, redactedKeys: redactedKeys)
    }

    private enum LogLevel {
        case debug
        case info
        case error
    }

    private func write(
        level: LogLevel,
        message: String,
        category: LogCategory,
        metadata: [String: String],
        redactedKeys: Set<String>
    ) {
        let logger = Logger(subsystem: "com.evan.retailrewardsrescue", category: category.rawValue)
        let metadataText = formatMetadata(metadata, redactedKeys: redactedKeys)
        let fullMessage = metadataText.isEmpty ? message : "\(message) | \(metadataText)"

        switch level {
        case .debug:
            logger.debug("\(fullMessage, privacy: .public)")
        case .info:
            logger.info("\(fullMessage, privacy: .public)")
        case .error:
            logger.error("\(fullMessage, privacy: .public)")
        }
    }

    private func formatMetadata(_ metadata: [String: String], redactedKeys: Set<String>) -> String {
        guard !metadata.isEmpty else {
            return ""
        }

        return metadata
            .sorted(by: { $0.key < $1.key })
            .map { key, value in
                if redactedKeys.contains(key) {
                    return "\(key)=<redacted>"
                }
                return "\(key)=\(value)"
            }
            .joined(separator: " ")
    }
}
