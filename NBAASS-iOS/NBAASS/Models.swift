import Foundation
import SwiftUI

struct Team: Identifiable, Codable, Hashable {
    var id: String { abbreviation }
    let abbreviation: String
    let name: String
    var fullName: String = ""
    var conference: String = ""
    var wins: Double = 0
    var losses: Double = 0
    var winRate: Double = 0
    var streak: String = ""
}

struct Game: Identifiable, Codable, Hashable {
    let id: String
    let status: String
    let time: String
    let homeTeam: Team
    let awayTeam: Team
    let homeScore: String
    let awayScore: String
}

struct Player: Identifiable, Codable, Hashable {
    let id: String
    let firstName: String
    let lastName: String
    let fullName: String
    let position: String
    let jerseyNumber: String
    let height: String
    let weight: String
    let age: Int?
    let experienceYears: Int?
    let headshot: String
    let team: PlayerTeam?
    let stats: PlayerStats?

    struct PlayerStats: Codable, Hashable {
        let season: Int
        let gamesPlayed: Double
        let minutes: Double
        let points: Double
        let rebounds: Double
        let assists: Double
        let steals: Double
        let blocks: Double
        let turnovers: Double
        let fieldGoalPct: Double
        let threePointPct: Double
        let freeThrowPct: Double
        let fieldGoalsMade: Double
        let fieldGoalsAttempted: Double
        let threePointersMade: Double
        let threePointersAttempted: Double
        let freeThrowsMade: Double
        let freeThrowsAttempted: Double

        enum CodingKeys: String, CodingKey {
            case season, minutes, points, rebounds, assists, steals, blocks, turnovers
            case gamesPlayed = "games_played"
            case fieldGoalPct = "field_goal_pct"
            case threePointPct = "three_point_pct"
            case freeThrowPct = "free_throw_pct"
            case fieldGoalsMade = "field_goals_made"
            case fieldGoalsAttempted = "field_goals_attempted"
            case threePointersMade = "three_pointers_made"
            case threePointersAttempted = "three_pointers_attempted"
            case freeThrowsMade = "free_throws_made"
            case freeThrowsAttempted = "free_throws_attempted"
        }
    }

    struct PlayerTeam: Codable, Hashable {
        let id: String
        let abbreviation: String
        let fullName: String

        enum CodingKeys: String, CodingKey {
            case id, abbreviation
            case fullName = "full_name"
        }
    }

    enum CodingKeys: String, CodingKey {
        case id, position, height, weight, age, headshot, team, stats
        case firstName = "first_name"
        case lastName = "last_name"
        case fullName = "full_name"
        case jerseyNumber = "jersey_number"
        case experienceYears = "experience_years"
    }
}

struct WatchLink: Identifiable, Codable, Hashable {
    var id = UUID()
    var name: String
    var url: String
}

struct PlayoffSeries: Identifiable {
    let id = UUID()
    let team1: Team?
    let team2: Team?
    var wins1: Int? = nil
    var wins2: Int? = nil
    var label: String = ""
}

struct PlayoffBracket: Codable {
    let season: Int
    let seasonDisplay: String
    let series: [PlayoffSeriesData]

    enum CodingKeys: String, CodingKey {
        case season, series
        case seasonDisplay = "season_display"
    }
}

struct PlayoffSeriesData: Identifiable, Codable, Hashable {
    let id: String
    let round: String
    let conference: String
    let completed: Bool
    let summary: String
    let teams: [PlayoffSeriesTeam]
}

struct PlayoffSeriesTeam: Codable, Hashable {
    let abbreviation: String
    let seed: Int?
    let conference: String?
    let wins: Int
}

enum TeamCatalog {
    struct Info { let name: String; let color: String; let slug: String }

    static let teams: [String: Info] = [
        "ATL": .init(name: "老鹰", color: "#E03A3E", slug: "atl"), "BOS": .init(name: "凯尔特人", color: "#00A650", slug: "bos"),
        "BKN": .init(name: "篮网", color: "#D6D9DE", slug: "bkn"), "CHA": .init(name: "黄蜂", color: "#00A5B5", slug: "cha"),
        "CHI": .init(name: "公牛", color: "#CE1141", slug: "chi"), "CLE": .init(name: "骑士", color: "#C41E4A", slug: "cle"),
        "DAL": .init(name: "独行侠", color: "#0064B1", slug: "dal"), "DEN": .init(name: "掘金", color: "#FEC524", slug: "den"),
        "DET": .init(name: "活塞", color: "#ED174C", slug: "det"), "GSW": .init(name: "勇士", color: "#FDB927", slug: "gs"),
        "HOU": .init(name: "火箭", color: "#CE1141", slug: "hou"), "IND": .init(name: "步行者", color: "#FDBB30", slug: "ind"),
        "LAC": .init(name: "快船", color: "#ED174C", slug: "lac"), "LAL": .init(name: "湖人", color: "#F9A01B", slug: "lal"),
        "MEM": .init(name: "灰熊", color: "#7399C6", slug: "mem"), "MIA": .init(name: "热火", color: "#F9423A", slug: "mia"),
        "MIL": .init(name: "雄鹿", color: "#00A94F", slug: "mil"), "MIN": .init(name: "森林狼", color: "#78BE20", slug: "min"),
        "NOP": .init(name: "鹈鹕", color: "#C8102E", slug: "no"), "NYK": .init(name: "尼克斯", color: "#F58426", slug: "ny"),
        "OKC": .init(name: "雷霆", color: "#007AC1", slug: "okc"), "ORL": .init(name: "魔术", color: "#0B77BD", slug: "orl"),
        "PHI": .init(name: "76人", color: "#1D74C4", slug: "phi"), "PHX": .init(name: "太阳", color: "#E56020", slug: "phx"),
        "POR": .init(name: "开拓者", color: "#E03A3E", slug: "por"), "SAC": .init(name: "国王", color: "#7B4EA8", slug: "sac"),
        "SAS": .init(name: "马刺", color: "#C4CED4", slug: "sa"), "TOR": .init(name: "猛龙", color: "#CE1141", slug: "tor"),
        "UTA": .init(name: "爵士", color: "#4E9BD6", slug: "utah"), "WAS": .init(name: "奇才", color: "#E31837", slug: "wsh")
    ]

    static let aliases = ["GS":"GSW", "NY":"NYK", "SA":"SAS", "UT":"UTA", "UTAH":"UTA", "WSH":"WAS", "PHO":"PHX", "BRK":"BKN", "CHO":"CHA", "NO":"NOP", "LA":"LAL"]
    static func normalize(_ value: String) -> String { aliases[value.uppercased()] ?? value.uppercased() }
    static func info(_ abbreviation: String) -> Info? { teams[normalize(abbreviation)] }
    static func team(_ abbreviation: String, fullName: String = "", conference: String = "") -> Team {
        let key = normalize(abbreviation)
        return Team(abbreviation: key, name: info(key)?.name ?? key, fullName: fullName, conference: conference)
    }
    static func color(_ abbreviation: String) -> Color { Color(hex: info(abbreviation)?.color ?? "#8A8F98") }
    static func logoAssetName(_ abbreviation: String) -> String? {
        let key = normalize(abbreviation)
        return teams[key] == nil ? nil : "TeamLogo\(key)"
    }
    static func logoURL(_ abbreviation: String) -> URL? {
        guard let slug = info(abbreviation)?.slug else { return nil }
        return URL(string: "https://a.espncdn.com/i/teamlogos/nba/500/\(slug).png")
    }
}

extension Date {
    static let dayFormatter: DateFormatter = { let f = DateFormatter(); f.locale = Locale(identifier: "zh_CN"); f.dateFormat = "yyyy-MM-dd"; return f }()
    static let weekdayFormatter: DateFormatter = { let f = DateFormatter(); f.locale = Locale(identifier: "zh_CN"); f.dateFormat = "EEE"; return f }()
    var dayKey: String { Date.dayFormatter.string(from: self) }
}
