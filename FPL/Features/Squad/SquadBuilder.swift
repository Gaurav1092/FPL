import Foundation

struct SquadSection: Equatable, Sendable {
    let position: Position
    let players: [Player]
}

enum SquadBuilder {
    /// Groups players by position (goalkeepers first), best-scoring first within each group.
    /// Only players matching `query` are included, and positions left empty are omitted.
    static func sections(for players: [Player], matching query: String = "") -> [SquadSection] {
        let query = query.trimmingCharacters(in: .whitespacesAndNewlines)
        let matching = query.isEmpty ? players : players.filter { $0.matches(query) }
        let playersByPosition = Dictionary(grouping: matching, by: \.position)

        return Position.allCases.compactMap { position in
            guard let players = playersByPosition[position] else { return nil }
            return SquadSection(position: position, players: players.sorted(by: ranksAbove))
        }
    }

    /// Most points first. Ties are broken by name so the order stays the same across refreshes.
    static func ranksAbove(_ lhs: Player, _ rhs: Player) -> Bool {
        if lhs.totalPoints != rhs.totalPoints {
            return lhs.totalPoints > rhs.totalPoints
        }
        return lhs.webName.localizedStandardCompare(rhs.webName) == .orderedAscending
    }
}

extension Player {
    /// Case- and accent-insensitive, so "martinez" finds "Martínez".
    func matches(_ query: String) -> Bool {
        [webName, fullName].contains {
            $0.range(of: query, options: [.caseInsensitive, .diacriticInsensitive]) != nil
        }
    }
}
