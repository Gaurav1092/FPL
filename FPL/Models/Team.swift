struct Team: Identifiable, Hashable, Sendable {
    let id: Int
    let name: String
    let shortName: String
    let players: [Player]

    var playerCount: Int { players.count }
}
