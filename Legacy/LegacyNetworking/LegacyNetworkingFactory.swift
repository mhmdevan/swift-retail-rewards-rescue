import Alamofire
import Foundation

enum LegacyNetworkingFactory {
    static func makeDemoAlamofireSession() -> Session {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [DemoAPIURLProtocol.self]
        return Session(configuration: configuration)
    }

    static func makeDemoURLSession() -> URLSession {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [DemoAPIURLProtocol.self]
        return URLSession(configuration: configuration)
    }
}
