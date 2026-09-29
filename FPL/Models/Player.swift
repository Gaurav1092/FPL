struct Player: Identifiable, Hashable, Sendable {
    let id: Int
    let firstName: String
    let secondName: String
    /// The short name FPL shows in its own UI, e.g. "Saka".
    let webName: String
    let teamID: Int
    let position: Position
    /// Price in tenths of a million, as FPL reports it (65 == £6.5m).
    let cost: Int
    let totalPoints: Int

    var fullName: String { "\(firstName) \(secondName)" }

    /// Integer maths rather than `Double` formatting, so there's no rounding to think about.
    var formattedPrice: String { "£\(cost / 10).\(cost % 10)m" }
}
