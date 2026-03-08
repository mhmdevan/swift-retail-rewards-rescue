import Foundation
import MetricKit

final class MetricKitObserver: NSObject, MXMetricManagerSubscriber {
    static let shared = MetricKitObserver()

    private(set) var latestPayloadSummary: String = "No payloads received yet"

    private override init() {}

    func start() {
        MXMetricManager.shared.add(self)
    }

    func stop() {
        MXMetricManager.shared.remove(self)
    }

    func didReceive(_ payloads: [MXMetricPayload]) {
        latestPayloadSummary = "Received \(payloads.count) metric payload(s)"
        AppLogger.shared.info(latestPayloadSummary, category: .background)
    }

    func didReceive(_ payloads: [MXDiagnosticPayload]) {
        let summary = "Received \(payloads.count) diagnostic payload(s)"
        latestPayloadSummary = summary
        AppLogger.shared.info(summary, category: .background)
    }
}
