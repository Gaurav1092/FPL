import XCTest
@testable import FPL

final class FPLAPIClientTests: XCTestCase {
    func testReturnsDataFromBootstrapEndpoint() async throws {
        let client = FPLAPIClient(httpClient: MockHTTPClient { request in
            XCTAssertEqual(request.url, FPLAPIClient.bootstrapURL)
            let response = HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: nil, headerFields: nil)!
            return (Fixtures.bootstrapData, response)
        })

        let data = try await client.fetchBootstrap()

        XCTAssertEqual(data, Fixtures.bootstrapData)
    }

    func testNonSuccessStatusThrowsServerError() async {
        let client = FPLAPIClient(httpClient: MockHTTPClient.responding(statusCode: 503))

        await assertThrows(.server(statusCode: 503), try await client.fetchBootstrap())
    }

    func testNoConnectionThrowsOffline() async {
        let client = FPLAPIClient(httpClient: MockHTTPClient.failing(with: URLError(.notConnectedToInternet)))

        await assertThrows(.offline, try await client.fetchBootstrap())
    }

    func testOtherURLErrorsThrowNetworkError() async {
        let client = FPLAPIClient(httpClient: MockHTTPClient.failing(with: URLError(.timedOut)))

        await assertThrows(.network, try await client.fetchBootstrap())
    }
}
