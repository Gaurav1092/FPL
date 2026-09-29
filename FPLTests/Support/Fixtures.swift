import Foundation

/// A trimmed-down `bootstrap-static` payload. It keeps some fields the app ignores (`events`,
/// `code`, `status`, ...) to prove decoding tolerates them, and includes an element type 5
/// (manager) that should be filtered out.
enum Fixtures {
    static let bootstrapData = Data(bootstrapJSON.utf8)

    private static let bootstrapJSON = """
    {
      "events": [],
      "element_types": [
        { "id": 1, "singular_name_short": "GKP" },
        { "id": 5, "singular_name_short": "MNG" }
      ],
      "teams": [
        { "id": 2, "code": 7, "name": "Aston Villa", "short_name": "AVL", "strength": 4 },
        { "id": 1, "code": 3, "name": "Arsenal", "short_name": "ARS", "strength": 5 },
        { "id": 3, "code": 91, "name": "Bournemouth", "short_name": "BOU", "strength": 3 }
      ],
      "elements": [
        \(player(id: 1, first: "David", second: "Raya Martín", web: "Raya", team: 1, type: 1, cost: 55, points: 120)),
        \(player(id: 2, first: "Gabriel", second: "dos Santos Magalhães", web: "Gabriel", team: 1, type: 2, cost: 60, points: 150)),
        \(player(id: 3, first: "William", second: "Saliba", web: "Saliba", team: 1, type: 2, cost: 60, points: 150)),
        \(player(id: 4, first: "Bukayo", second: "Saka", web: "Saka", team: 1, type: 3, cost: 100, points: 180)),
        \(player(id: 5, first: "Kai", second: "Havertz", web: "Havertz", team: 1, type: 4, cost: 80, points: 130)),
        \(player(id: 6, first: "Mikel", second: "Arteta", web: "Arteta", team: 1, type: 5, cost: 5, points: 40)),
        \(player(id: 7, first: "Emiliano", second: "Martínez Romero", web: "Martínez", team: 2, type: 1, cost: 50, points: 110)),
        \(player(id: 8, first: "Ollie", second: "Watkins", web: "Watkins", team: 2, type: 4, cost: 90, points: 170))
      ]
    }
    """

    private static func player(id: Int, first: String, second: String, web: String, team: Int, type: Int, cost: Int, points: Int) -> String {
        """
        { "id": \(id), "code": \(id * 1000), "first_name": "\(first)", "second_name": "\(second)", "web_name": "\(web)", \
        "team": \(team), "element_type": \(type), "now_cost": \(cost), "total_points": \(points), "status": "a" }
        """
    }
}
