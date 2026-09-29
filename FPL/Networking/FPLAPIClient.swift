import Foundation

struct FPLAPIClient: Sendable {
    static let bootstrapURL = URL(string: "https://fantasy.premierleague.com/api/bootstrap-static/")!

    private let httpClient: any HTTPClient

    init(httpClient: any HTTPClient) {
        self.httpClient = httpClient
    }

    /// Returns the raw `bootstrap-static` payload. It's left undecoded so the repository
    /// can cache exactly what the server sent.
    func fetchBootstrap() async throws -> Data {
        // We keep our own offline copy, so always go to the server rather than URLCache.
        let request = URLRequest(url: Self.bootstrapURL, cachePolicy: .reloadIgnoringLocalCacheData, timeoutInterval: 20)
        let (data, response) = try await send(request)

        guard let httpResponse = response as? HTTPURLResponse else { throw FPLError.network }
        guard (200..<300).contains(httpResponse.statusCode) else {
            throw FPLError.server(statusCode: httpResponse.statusCode)
        }
        return data
    }

    private func send(_ request: URLRequest) async throws -> (Data, URLResponse) {
        do {
            return try await httpClient.data(for: request)
        } catch let error as URLError {
            throw FPLError(error)
        }
    }
}
