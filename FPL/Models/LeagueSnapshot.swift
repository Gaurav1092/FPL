import Foundation

/// Everything the UI needs: all teams with their players, and when that data was fetched.
struct LeagueSnapshot: Equatable, Sendable {
    let teams: [Team]
    let updatedAt: Date
}

extension LeagueSnapshot {
    init(response: BootstrapResponse, updatedAt: Date) {
        let players = response.elements.compactMap(Player.init(dto:))
        let playersByTeam = Dictionary(grouping: players, by: \.teamID)

        let teams = response.teams
            .map { Team(id: $0.id, name: $0.name, shortName: $0.shortName, players: playersByTeam[$0.id] ?? []) }
            .sorted { $0.name.localizedStandardCompare($1.name) == .orderedAscending }

        self.init(teams: teams, updatedAt: updatedAt)
    }
}

private extension Player {
    /// Returns `nil` for element types that aren't playing positions.
    init?(dto: BootstrapResponse.PlayerDTO) {
        guard let position = Position(rawValue: dto.elementType) else { return nil }
        self.init(
            id: dto.id,
            firstName: dto.firstName,
            secondName: dto.secondName,
            webName: dto.webName,
            teamID: dto.team,
            position: position,
            cost: dto.nowCost,
            totalPoints: dto.totalPoints
        )
    }
}
