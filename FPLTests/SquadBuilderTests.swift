import XCTest
@testable import FPL

final class SquadBuilderTests: XCTestCase {
    private let players: [Player] = [
        .stub(id: 1, firstName: "Ollie", secondName: "Watkins", webName: "Watkins", position: .forward, points: 170),
        .stub(id: 2, firstName: "Emiliano", secondName: "Martínez Romero", webName: "Martínez", position: .goalkeeper, points: 110),
        .stub(id: 3, firstName: "Ezri", secondName: "Konsa", webName: "Konsa", position: .defender, points: 90),
        .stub(id: 4, firstName: "Pau", secondName: "Torres", webName: "Torres", position: .defender, points: 120),
        .stub(id: 5, firstName: "Matty", secondName: "Cash", webName: "Cash", position: .defender, points: 120),
    ]

    func testGroupsByPositionInPitchOrderAndOmitsEmptyPositions() {
        let sections = SquadBuilder.sections(for: players)

        XCTAssertEqual(sections.map(\.position), [.goalkeeper, .defender, .forward])
    }

    func testOrdersByPointsDescendingThenName() {
        let defenders = SquadBuilder.sections(for: players).first { $0.position == .defender }

        XCTAssertEqual(defenders?.players.map(\.webName), ["Cash", "Torres", "Konsa"])
    }

    func testSearchIsCaseInsensitive() {
        let sections = SquadBuilder.sections(for: players, matching: "WAT")

        XCTAssertEqual(sections.flatMap(\.players).map(\.id), [1])
    }

    func testSearchIgnoresAccents() {
        let sections = SquadBuilder.sections(for: players, matching: "martinez")

        XCTAssertEqual(sections.flatMap(\.players).map(\.id), [2])
    }

    func testSearchMatchesFullName() {
        let sections = SquadBuilder.sections(for: players, matching: "emiliano")

        XCTAssertEqual(sections.flatMap(\.players).map(\.id), [2])
    }

    func testBlankQueryReturnsEveryone() {
        let sections = SquadBuilder.sections(for: players, matching: "   ")

        XCTAssertEqual(sections.flatMap(\.players).count, players.count)
    }

    func testNoMatchesReturnsNoSections() {
        XCTAssertTrue(SquadBuilder.sections(for: players, matching: "zzz").isEmpty)
    }
}
