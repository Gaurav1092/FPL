@testable import FPL

extension Player {
    static func stub(
        id: Int,
        firstName: String = "Test",
        secondName: String = "Player",
        webName: String,
        position: Position = .midfielder,
        cost: Int = 50,
        points: Int = 0
    ) -> Player {
        Player(
            id: id,
            firstName: firstName,
            secondName: secondName,
            webName: webName,
            teamID: 1,
            position: position,
            cost: cost,
            totalPoints: points
        )
    }
}
