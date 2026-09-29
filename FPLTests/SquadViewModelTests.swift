import XCTest
@testable import FPL

final class SquadViewModelTests: XCTestCase {
    private let team = Team(id: 1, name: "Arsenal", shortName: "ARS", players: [
        .stub(id: 1, webName: "Saka", position: .midfielder, points: 180),
        .stub(id: 2, webName: "Raya", position: .goalkeeper, points: 120),
    ])

    @MainActor
    func testStartsWithWholeSquad() {
        let viewModel = SquadViewModel(team: team)

        XCTAssertEqual(viewModel.sections.map(\.position), [.goalkeeper, .midfielder])
        XCTAssertNil(viewModel.emptyMessage)
    }

    @MainActor
    func testSearchFiltersAndNotifies() {
        let viewModel = SquadViewModel(team: team)
        var changeCount = 0
        viewModel.onChange = { changeCount += 1 }

        viewModel.search("sak")

        XCTAssertEqual(viewModel.sections.flatMap(\.players).map(\.webName), ["Saka"])
        XCTAssertEqual(changeCount, 1)
    }

    @MainActor
    func testRepeatingSameQueryDoesNotNotify() {
        let viewModel = SquadViewModel(team: team)
        var changeCount = 0
        viewModel.onChange = { changeCount += 1 }

        viewModel.search("sak")
        viewModel.search("sak")

        XCTAssertEqual(changeCount, 1)
    }

    @MainActor
    func testNoResultsProducesEmptyMessage() {
        let viewModel = SquadViewModel(team: team)

        viewModel.search("  zzz ")

        XCTAssertEqual(viewModel.emptyMessage, "No players match “zzz”.")
    }

    @MainActor
    func testEmptySquadProducesEmptyMessage() {
        let viewModel = SquadViewModel(team: Team(id: 2, name: "Empty", shortName: "EMP", players: []))

        XCTAssertEqual(viewModel.emptyMessage, "No players in this squad.")
    }
}
