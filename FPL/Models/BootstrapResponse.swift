import Foundation

/// The parts of `bootstrap-static` this app uses. Everything else in the payload is ignored.
struct BootstrapResponse: Decodable, Sendable {
    struct TeamDTO: Decodable, Sendable {
        let id: Int
        let name: String
        let shortName: String
    }

    struct PlayerDTO: Decodable, Sendable {
        let id: Int
        let firstName: String
        let secondName: String
        let webName: String
        let team: Int
        let elementType: Int
        let nowCost: Int
        let totalPoints: Int
    }

    let teams: [TeamDTO]
    let elements: [PlayerDTO]

    static func decode(from data: Data) throws -> BootstrapResponse {
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        do {
            return try decoder.decode(BootstrapResponse.self, from: data)
        } catch {
            throw FPLError.decoding
        }
    }
}
