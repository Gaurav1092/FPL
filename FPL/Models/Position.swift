/// A player's position, mapped from FPL's `element_type`.
///
/// Only the four playing positions are modelled. Other element types (e.g. `5`, the
/// "Manager" type FPL added in 2024/25) are dropped when mapping the API response.
enum Position: Int, CaseIterable, Sendable {
    case goalkeeper = 1
    case defender = 2
    case midfielder = 3
    case forward = 4

    var pluralName: String {
        switch self {
        case .goalkeeper: "Goalkeepers"
        case .defender: "Defenders"
        case .midfielder: "Midfielders"
        case .forward: "Forwards"
        }
    }

    var shortName: String {
        switch self {
        case .goalkeeper: "GKP"
        case .defender: "DEF"
        case .midfielder: "MID"
        case .forward: "FWD"
        }
    }
}
