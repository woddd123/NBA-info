import Foundation
import Combine

enum WidgetGameCache {
    static let suiteName = "group.com.nbaass.ios"
    static let key = "today_games"

    static func save(_ games: [Game]) {
        guard let defaults = UserDefaults(suiteName: suiteName),
              let data = try? JSONEncoder().encode(games) else { return }
        defaults.set(data, forKey: key)
        defaults.set(Date(), forKey: "today_games_updated_at")
    }
}

@MainActor
final class StorageService: ObservableObject {
    @Published var links: [WatchLink] { didSet { saveLinks() } }

    static let defaultLinks = [
        WatchLink(name: "腾讯体育", url: "https://sports.qq.com/nba/"),
        WatchLink(name: "CCTV5 体育频道", url: "https://tv.cctv.com/live/cctv5"),
        WatchLink(name: "咪咕视频 NBA", url: "https://www.miguvideo.com/wap/resource/pc/pages/nba/index.html"),
        WatchLink(name: "NBA 官网", url: "https://www.nba.com/watch/")
    ]

    init() {
        if let data = UserDefaults.standard.data(forKey: "nba_links"), let saved = try? JSONDecoder().decode([WatchLink].self, from: data) {
            links = saved
        } else {
            links = Self.defaultLinks
        }
    }

    private func saveLinks() {
        if let data = try? JSONEncoder().encode(links) { UserDefaults.standard.set(data, forKey: "nba_links") }
    }

    func clearCache() { URLCache.shared.removeAllCachedResponses() }
    func reset() {
        UserDefaults.standard.removeObject(forKey: "nba_links")
        links = Self.defaultLinks
        clearCache()
    }
}

enum NBAServiceError: LocalizedError {
    case invalidResponse, malformedData
    var errorDescription: String? { "数据源暂时不可用，请稍后重试。" }
}

enum NBAService {
    private static let productionDataBase = "https://api.woddd.icu/api/v1"

    // Xcode 自动生成 Info.plist 时，未知的 INFOPLIST_KEY_* 可能不会进入最终安装包。
    // 因此正式 API 使用代码内安全默认值，同时仍允许显式 Info.plist 覆盖。
    private static var dataBase: String {
        guard let value = Bundle.main.object(forInfoDictionaryKey: "NBAASS_API_BASE") as? String,
              value.hasPrefix("https://") else { return productionDataBase }
        return value.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
    }
    private static let espnBase = "https://site.api.espn.com/apis"

    private static func json(url: URL, reload: Bool) async throws -> [String: Any] {
        var request = URLRequest(url: url, cachePolicy: reload ? .reloadIgnoringLocalCacheData : .returnCacheDataElseLoad, timeoutInterval: 15)
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        let (data, response) = try await URLSession.shared.data(for: request)
        guard (response as? HTTPURLResponse)?.statusCode == 200,
              let root = try JSONSerialization.jsonObject(with: data) as? [String: Any] else { throw NBAServiceError.invalidResponse }
        return root
    }

    private static func endpoint(_ serverPath: String, espnPath: String) throws -> URL {
        let raw = dataBase + serverPath
        guard let url = URL(string: raw) else { throw NBAServiceError.invalidResponse }
        return url
    }

    static func games(on date: Date, reload: Bool = false) async throws -> [Game] {
        let queryDate = Calendar(identifier: .gregorian).date(byAdding: .day, value: -1, to: date) ?? date
        let formatter = DateFormatter(); formatter.dateFormat = "yyyyMMdd"
        let refresh = reload ? "&refresh=1" : ""
        let url = try endpoint("/games?date=\(date.dayKey)\(refresh)", espnPath: "/site/v2/sports/basketball/nba/scoreboard?dates=\(formatter.string(from: queryDate))")
        let root = try await json(url: url, reload: reload)
        let events = root["events"] as? [[String: Any]] ?? []
        return events.compactMap(parseGame)
    }

    private static func parseGame(_ event: [String: Any]) -> Game? {
        guard let id = event["id"] as? String,
              let competition = (event["competitions"] as? [[String: Any]])?.first,
              let competitors = competition["competitors"] as? [[String: Any]],
              let home = competitors.first(where: { $0["homeAway"] as? String == "home" }),
              let away = competitors.first(where: { $0["homeAway"] as? String == "away" }),
              let homeData = home["team"] as? [String: Any], let awayData = away["team"] as? [String: Any] else { return nil }

        let statusRoot = event["status"] as? [String: Any]
        let type = statusRoot?["type"] as? [String: Any]
        let state = type?["state"] as? String ?? "pre"
        let status = state == "post" ? "已结束" : state == "pre" ? "未开始" : "进行中"
        var time = ""
        if state == "pre", let raw = event["date"] as? String, let date = ISO8601DateFormatter().date(from: raw) {
            let f = DateFormatter(); f.dateFormat = "HH:mm"; time = f.string(from: date)
        } else if state != "post" { time = type?["shortDetail"] as? String ?? "" }

        let team: ([String: Any]) -> Team = { data in
            let abbr = data["abbreviation"] as? String ?? ""
            return TeamCatalog.team(abbr, fullName: data["displayName"] as? String ?? "")
        }
        return Game(id: id, status: status, time: time, homeTeam: team(homeData), awayTeam: team(awayData), homeScore: home["score"] as? String ?? "0", awayScore: away["score"] as? String ?? "0")
    }

    struct StandingsResult {
        let teams: [Team]
        let seasonLabel: String
    }

    static func standings(reload: Bool = false) async throws -> StandingsResult {
        let refresh = reload ? "?refresh=1" : ""
        let url = try endpoint("/standings\(refresh)", espnPath: "/v2/sports/basketball/nba/standings")
        let root = try await json(url: url, reload: reload)
        let conferences = root["children"] as? [[String: Any]] ?? []
        let teams = conferences.flatMap { conference -> [Team] in
            let name = conference["name"] as? String == "Eastern Conference" ? "East" : "West"
            let standing = conference["standings"] as? [String: Any]
            let entries = standing?["entries"] as? [[String: Any]] ?? []
            return entries.compactMap { entry in
                guard let data = entry["team"] as? [String: Any], let abbr = data["abbreviation"] as? String else { return nil }
                let stats = entry["stats"] as? [[String: Any]] ?? []
                func value(_ key: String) -> Double { stats.first { $0["name"] as? String == key }?["value"] as? Double ?? 0 }
                let streak = stats.first { $0["name"] as? String == "streak" }?["displayValue"] as? String ?? ""
                return Team(abbreviation: TeamCatalog.normalize(abbr), name: TeamCatalog.info(abbr)?.name ?? abbr, fullName: data["displayName"] as? String ?? "", conference: name, wins: value("wins"), losses: value("losses"), winRate: value("winPercent"), streak: streak)
            }
        }
        let seasonLabel = (conferences.first?["standings"] as? [String: Any])?["seasonDisplayName"] as? String
            ?? (root["season"] as? [String: Any])?["displayName"] as? String
            ?? "最近赛季"
        return StandingsResult(teams: teams, seasonLabel: seasonLabel)
    }

    static func players(page: Int = 1, perPage: Int = 600, reload: Bool = false) async throws -> [Player] {
        let refresh = reload ? "&refresh=1" : ""
        let url = try endpoint("/players?page=\(page)&per_page=\(perPage)\(refresh)", espnPath: "")
        var request = URLRequest(url: url, cachePolicy: reload ? .reloadIgnoringLocalCacheData : .returnCacheDataElseLoad, timeoutInterval: 30)
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        let (data, response) = try await URLSession.shared.data(for: request)
        guard (response as? HTTPURLResponse)?.statusCode == 200 else { throw NBAServiceError.invalidResponse }
        struct Response: Decodable { let data: [Player] }
        return try JSONDecoder().decode(Response.self, from: data).data
    }

    static func playoffs(reload: Bool = false) async throws -> PlayoffBracket {
        let refresh = reload ? "?refresh=1" : ""
        let url = try endpoint("/playoffs\(refresh)", espnPath: "")
        var request = URLRequest(url: url, cachePolicy: reload ? .reloadIgnoringLocalCacheData : .returnCacheDataElseLoad, timeoutInterval: 30)
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        let (data, response) = try await URLSession.shared.data(for: request)
        guard (response as? HTTPURLResponse)?.statusCode == 200 else { throw NBAServiceError.invalidResponse }
        return try JSONDecoder().decode(PlayoffBracket.self, from: data)
    }

    static func playoffScores(reload: Bool = false) async -> [String: [String: Int]] {
        let calendar = Calendar(identifier: .gregorian)
        let year = calendar.component(.year, from: Date())
        guard let start = calendar.date(from: DateComponents(year: year, month: 4, day: 15)),
              let seasonEnd = calendar.date(from: DateComponents(year: year, month: 6, day: 30)) else { return [:] }
        let end = min(Date(), seasonEnd)
        guard start <= end else { return [:] }
        let formatter = DateFormatter(); formatter.dateFormat = "yyyyMMdd"
        var dates: [String] = []
        var cursor = start
        while cursor <= end {
            dates.append(formatter.string(from: cursor))
            cursor = calendar.date(byAdding: .day, value: 1, to: cursor) ?? end.addingTimeInterval(1)
        }

        return await withTaskGroup(of: [String: [String: Int]].self) { group in
            for date in dates {
                group.addTask {
                    let rawDate = Date.dayFormatter.date(from: "\(date.prefix(4))-\(date.dropFirst(4).prefix(2))-\(date.suffix(2))") ?? Date()
                    let beijingDate = Calendar(identifier: .gregorian).date(byAdding: .day, value: 1, to: rawDate) ?? rawDate
                    guard let url = try? endpoint("/games?date=\(beijingDate.dayKey)\(reload ? "&refresh=1" : "")", espnPath: "/site/v2/sports/basketball/nba/scoreboard?dates=\(date)"),
                          let root = try? await json(url: url, reload: reload) else { return [:] }
                    return extractSeries(from: root)
                }
            }
            var merged: [String: [String: Int]] = [:]
            for await day in group {
                for (key, score) in day { merged[key] = score }
            }
            return merged
        }
    }

    private static func extractSeries(from root: [String: Any]) -> [String: [String: Int]] {
        var result: [String: [String: Int]] = [:]
        let events = root["events"] as? [[String: Any]] ?? []
        for event in events {
            guard let competition = (event["competitions"] as? [[String: Any]])?.first,
                  let competitors = competition["competitors"] as? [[String: Any]],
                  let series = competition["series"] as? [String: Any],
                  let seriesCompetitors = series["competitors"] as? [[String: Any]] else { continue }
            var idToAbbr: [String: String] = [:]
            for competitor in competitors {
                guard let team = competitor["team"] as? [String: Any], let id = team["id"] as? String, let abbr = team["abbreviation"] as? String else { continue }
                idToAbbr[id] = TeamCatalog.normalize(abbr)
            }
            let abbreviations = Array(idToAbbr.values).sorted()
            guard abbreviations.count == 2 else { continue }
            let key = abbreviations.joined(separator: "-")
            var wins: [String: Int] = [:]
            for competitor in seriesCompetitors {
                guard let id = competitor["id"] as? String, let abbr = idToAbbr[id] else { continue }
                wins[abbr] = competitor["wins"] as? Int ?? 0
            }
            result[key] = wins
        }
        return result
    }
}
