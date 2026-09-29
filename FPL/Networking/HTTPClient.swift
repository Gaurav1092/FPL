import Foundation

/// The one piece of `URLSession` the app uses, behind a protocol so tests never hit the network.
protocol HTTPClient: Sendable {
    func data(for request: URLRequest) async throws -> (Data, URLResponse)
}

extension URLSession: HTTPClient {
    // `URLSession`'s own method has an extra defaulted `delegate:` parameter, which
    // doesn't satisfy the protocol requirement on its own.
    func data(for request: URLRequest) async throws -> (Data, URLResponse) {
        try await data(for: request, delegate: nil)
    }
}
