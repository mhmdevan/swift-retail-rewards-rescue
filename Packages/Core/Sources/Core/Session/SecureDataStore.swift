import Foundation

public protocol SecureDataStoring {
    func read(for key: String) throws -> Data?
    func write(_ data: Data, for key: String) throws
    func delete(for key: String) throws
}
