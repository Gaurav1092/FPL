import Foundation
@testable import FPL

/// Returns a fixed cached value and hands out queued fetch results one call at a time.
actor StubLeagueRepository: LeagueRepository {
    private let cached: LeagueSnapshot?
    private var fetchResults: [Result<LeagueSnapshot, FPLError>]

    init(cached: LeagueSnapshot? = nil, fetchResults: [Result<LeagueSnapshot, FPLError>]) {
        self.cached = cached
        self.fetchResults = fetchResults
    }

    func cachedLeague() -> LeagueSnapshot? {
        cached
    }

    func fetchLeague() throws -> LeagueSnapshot {
        try fetchResults.removeFirst().get()
    }
}

extension LeagueSnapshot {
    static func stub(teamNames: [String], updatedAt: Date = Date(timeIntervalSince1970: 0)) -> LeagueSnapshot {
        let teams = teamNames.enumerated().map { index, name in
            Team(id: index + 1, name: name, shortName: String(name.prefix(3)).uppercased(), players: [])
        }
        return LeagueSnapshot(teams: teams, updatedAt: updatedAt)
    }
}
