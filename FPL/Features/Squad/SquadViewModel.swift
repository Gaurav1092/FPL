import Foundation

/// The squad is already in memory, so searching is synchronous: no debounce and no
/// in-flight requests to cancel.
@MainActor
final class SquadViewModel {
    let team: Team
    private(set) var sections: [SquadSection]
    private(set) var query = ""

    var onChange: (() -> Void)?

    init(team: Team) {
        self.team = team
        sections = SquadBuilder.sections(for: team.players)
    }

    func search(_ query: String) {
        guard query != self.query else { return }
        self.query = query
        sections = SquadBuilder.sections(for: team.players, matching: query)
        onChange?()
    }

    /// Text for the empty state, or `nil` when there are players to show.
    var emptyMessage: String? {
        guard sections.isEmpty else { return nil }
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? "No players in this squad." : "No players match “\(trimmed)”."
    }
}
