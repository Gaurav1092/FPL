import Foundation
@testable import FPL

struct MockHTTPClient: HTTPClient {
    let handler: @Sendable (URLRequest) throws -> (Data, URLResponse)

    func data(for request: URLRequest) async throws -> (Data, URLResponse) {
        try handler(request)
    }

    static func responding(statusCode: Int, data: Data = Data()) -> MockHTTPClient {
        MockHTTPClient { request in
            let response = HTTPURLResponse(url: request.url!, statusCode: statusCode, httpVersion: nil, headerFields: nil)!
            return (data, response)
        }
    }

    static func failing(with error: URLError) -> MockHTTPClient {
        MockHTTPClient { _ in throw error }
    }
}
