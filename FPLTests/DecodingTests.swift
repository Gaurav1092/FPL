import XCTest
@testable import FPL

final class DecodingTests: XCTestCase {
    func testDecodesTeamsAndPlayersIgnoringUnusedFields() throws {
        let response = try BootstrapResponse.decode(from: Fixtures.bootstrapData)

        XCTAssertEqual(response.teams.count, 3)
        XCTAssertEqual(response.elements.count, 8)

        let saka = try XCTUnwrap(response.elements.first { $0.id == 4 })
        XCTAssertEqual(saka.webName, "Saka")
        XCTAssertEqual(saka.team, 1)
        XCTAssertEqual(saka.elementType, 3)
        XCTAssertEqual(saka.nowCost, 100)
        XCTAssertEqual(saka.totalPoints, 180)
    }

    func testMalformedJSONThrowsDecodingError() {
        XCTAssertThrowsError(try BootstrapResponse.decode(from: Data("{\"teams\": 1}".utf8))) { error in
            XCTAssertEqual(error as? FPLError, .decoding)
        }
    }

    func testSnapshotGroupsPlayersByTeamAndSortsTeamsByName() throws {
        let response = try BootstrapResponse.decode(from: Fixtures.bootstrapData)
        let snapshot = LeagueSnapshot(response: response, updatedAt: Date(timeIntervalSince1970: 0))

        XCTAssertEqual(snapshot.teams.map(\.name), ["Arsenal", "Aston Villa", "Bournemouth"])
        // Arsenal's manager (element type 5) is excluded.
        XCTAssertEqual(snapshot.teams.map(\.playerCount), [5, 2, 0])
        XCTAssertEqual(snapshot.teams[0].shortName, "ARS")
    }

    func testMapsPlayerFields() throws {
        let response = try BootstrapResponse.decode(from: Fixtures.bootstrapData)
        let snapshot = LeagueSnapshot(response: response, updatedAt: Date(timeIntervalSince1970: 0))
        let saka = try XCTUnwrap(snapshot.teams[0].players.first { $0.id == 4 })

        XCTAssertEqual(saka.position, .midfielder)
        XCTAssertEqual(saka.fullName, "Bukayo Saka")
        XCTAssertEqual(saka.formattedPrice, "£10.0m")
    }

    func testFormattedPrice() {
        XCTAssertEqual(Player.stub(id: 1, webName: "A", cost: 45).formattedPrice, "£4.5m")
        XCTAssertEqual(Player.stub(id: 2, webName: "B", cost: 105).formattedPrice, "£10.5m")
    }
}
