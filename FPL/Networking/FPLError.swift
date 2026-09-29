import Foundation

enum FPLError: Error, Equatable, Sendable {
    case offline
    case network
    case server(statusCode: Int)
    case decoding

    init(_ urlError: URLError) {
        switch urlError.code {
        case .notConnectedToInternet, .networkConnectionLost, .dataNotAllowed, .internationalRoamingOff:
            self = .offline
        default:
            self = .network
        }
    }

    var message: String {
        switch self {
        case .offline:
            "You appear to be offline."
        case .network:
            "Couldn't reach the Fantasy Premier League server."
        case .server(statusCode: 503):
            // FPL returns 503 while it processes gameweek updates.
            "FPL is being updated. Please try again shortly."
        case .server(let statusCode):
            "The server returned an error (\(statusCode))."
        case .decoding:
            "The server sent data in an unexpected format."
        }
    }
}
