import SwiftUI
import WidgetKit

private struct WidgetTeam: Codable, Hashable {
    let abbreviation: String
    let name: String
    var fullName = ""
    var conference = ""
    var wins: Double = 0
    var losses: Double = 0
    var winRate: Double = 0
    var streak = ""
}

private struct WidgetGame: Identifiable, Codable, Hashable {
    let id: String
    let status: String
    let time: String
    let homeTeam: WidgetTeam
    let awayTeam: WidgetTeam
    let homeScore: String
    let awayScore: String
}

private enum WidgetData {
    static let suiteName = "group.com.nbaass.ios"
    static let key = "today_games"

    static func cached() -> [WidgetGame] {
        guard let data = UserDefaults(suiteName: suiteName)?.data(forKey: key) else { return [] }
        return (try? JSONDecoder().decode([WidgetGame].self, from: data)) ?? []
    }

    static func fetch() async -> [WidgetGame] {
        let calendar = Calendar(identifier: .gregorian)
        let queryDate = calendar.date(byAdding: .day, value: -1, to: Date()) ?? Date()
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyyMMdd"
        let serverDateFormatter = DateFormatter()
        serverDateFormatter.dateFormat = "yyyy-MM-dd"
        let configuredBase = (Bundle.main.object(forInfoDictionaryKey: "NBAASS_API_BASE") as? String)
            .flatMap { $0.hasPrefix("https://") ? $0 : nil }
        let endpoint = configuredBase.map { $0.trimmingCharacters(in: CharacterSet(charactersIn: "/")) + "/games?date=\(serverDateFormatter.string(from: Date()))" }
            ?? "https://site.api.espn.com/apis/site/v2/sports/basketball/nba/scoreboard?dates=\(formatter.string(from: queryDate))"
        guard let url = URL(string: endpoint),
              let (data, response) = try? await URLSession.shared.data(from: url),
              (response as? HTTPURLResponse)?.statusCode == 200,
              let root = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else { return cached() }
        let events = root["events"] as? [[String: Any]] ?? []
        let games = events.compactMap(parse)
        if !games.isEmpty, let encoded = try? JSONEncoder().encode(games) {
            UserDefaults(suiteName: suiteName)?.set(encoded, forKey: key)
        }
        return games
    }

    private static func parse(_ event: [String: Any]) -> WidgetGame? {
        guard let id = event["id"] as? String,
              let competition = (event["competitions"] as? [[String: Any]])?.first,
              let competitors = competition["competitors"] as? [[String: Any]],
              let home = competitors.first(where: { $0["homeAway"] as? String == "home" }),
              let away = competitors.first(where: { $0["homeAway"] as? String == "away" }),
              let homeData = home["team"] as? [String: Any],
              let awayData = away["team"] as? [String: Any] else { return nil }
        let type = (event["status"] as? [String: Any])?["type"] as? [String: Any]
        let state = type?["state"] as? String ?? "pre"
        let status = state == "post" ? "已结束" : state == "pre" ? "未开始" : "进行中"
        var time = ""
        if state == "pre", let raw = event["date"] as? String, let date = ISO8601DateFormatter().date(from: raw) {
            let f = DateFormatter(); f.dateFormat = "HH:mm"; time = f.string(from: date)
        } else if state != "post" {
            time = type?["shortDetail"] as? String ?? ""
        }
        func team(_ data: [String: Any]) -> WidgetTeam {
            let abbr = data["abbreviation"] as? String ?? ""
            let names: [String: String] = ["ATL":"老鹰","BOS":"凯尔特人","BKN":"篮网","CHA":"黄蜂","CHI":"公牛","CLE":"骑士","DAL":"独行侠","DEN":"掘金","DET":"活塞","GS":"勇士","GSW":"勇士","HOU":"火箭","IND":"步行者","LAC":"快船","LAL":"湖人","MEM":"灰熊","MIA":"热火","MIL":"雄鹿","MIN":"森林狼","NOP":"鹈鹕","NY":"尼克斯","NYK":"尼克斯","OKC":"雷霆","ORL":"魔术","PHI":"76人","PHX":"太阳","POR":"开拓者","SAC":"国王","SA":"马刺","SAS":"马刺","TOR":"猛龙","UTA":"爵士","WAS":"奇才"]
            return WidgetTeam(abbreviation: abbr, name: names[abbr] ?? abbr, fullName: data["displayName"] as? String ?? "")
        }
        return WidgetGame(id: id, status: status, time: time, homeTeam: team(homeData), awayTeam: team(awayData), homeScore: home["score"] as? String ?? "0", awayScore: away["score"] as? String ?? "0")
    }
}

private struct ScoreEntry: TimelineEntry {
    let date: Date
    let games: [WidgetGame]
}

private struct ScoreProvider: TimelineProvider {
    func placeholder(in context: Context) -> ScoreEntry { ScoreEntry(date: Date(), games: Self.samples) }
    func getSnapshot(in context: Context, completion: @escaping (ScoreEntry) -> Void) {
        completion(ScoreEntry(date: Date(), games: WidgetData.cached().isEmpty ? Self.samples : WidgetData.cached()))
    }
    func getTimeline(in context: Context, completion: @escaping (Timeline<ScoreEntry>) -> Void) {
        Task {
            let games = await WidgetData.fetch()
            let interval: TimeInterval = games.contains(where: { $0.status == "进行中" }) ? 15 * 60 : 60 * 60
            completion(Timeline(entries: [ScoreEntry(date: Date(), games: games)], policy: .after(Date().addingTimeInterval(interval))))
        }
    }
    static let samples = [
        WidgetGame(id: "1", status: "进行中", time: "第3节 06:24", homeTeam: WidgetTeam(abbreviation: "LAL", name: "湖人"), awayTeam: WidgetTeam(abbreviation: "GSW", name: "勇士"), homeScore: "86", awayScore: "82"),
        WidgetGame(id: "2", status: "未开始", time: "10:30", homeTeam: WidgetTeam(abbreviation: "BOS", name: "凯尔特人"), awayTeam: WidgetTeam(abbreviation: "NYK", name: "尼克斯"), homeScore: "0", awayScore: "0")
    ]
}

private struct TeamMark: View {
    let team: WidgetTeam
    var body: some View {
        ZStack {
            Circle().fill(color.opacity(0.22))
            Text(team.abbreviation.prefix(3)).font(.system(size: 8, weight: .black, design: .rounded)).foregroundStyle(color)
        }
    }
    private var color: Color {
        let colors: [String: Color] = ["LAL":.purple,"GSW":.blue,"BOS":.green,"NYK":.orange,"MIA":.red,"CLE":.red,"OKC":.blue,"DEN":.yellow]
        return colors[team.abbreviation] ?? .gray
    }
}

private struct GameLine: View {
    let game: WidgetGame
    var body: some View {
        HStack(spacing: 7) {
            TeamMark(team: game.awayTeam).frame(width: 25, height: 25)
            Text(game.awayTeam.name).lineLimit(1)
            Spacer(minLength: 2)
            Text(score(game.awayScore)).fontWeight(.black).monospacedDigit()
            Text("·").foregroundStyle(.secondary)
            Text(score(game.homeScore)).fontWeight(.black).monospacedDigit()
            Spacer(minLength: 2)
            Text(game.homeTeam.name).lineLimit(1)
            TeamMark(team: game.homeTeam).frame(width: 25, height: 25)
        }
        .font(.system(size: 12, weight: .semibold, design: .rounded))
    }
    private func score(_ value: String) -> String { game.status == "未开始" ? "–" : value }
}

private struct ScoreWidgetView: View {
    @Environment(\.widgetFamily) private var family
    let entry: ScoreEntry
    var body: some View {
        if entry.games.isEmpty { emptyView } else if family == .systemSmall { smallView(entry.games[0]) } else { mediumView }
    }
    private func smallView(_ game: WidgetGame) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            header
            Spacer(minLength: 0)
            HStack {
                teamColumn(game.awayTeam, score: game.awayScore)
                VStack(spacing: 3) {
                    Text(game.status == "未开始" ? "VS" : "—").font(.caption.bold()).foregroundStyle(.secondary)
                    Text(game.time.isEmpty ? game.status : game.time).font(.system(size: 9, weight: .semibold)).foregroundStyle(statusColor).lineLimit(1)
                }
                teamColumn(game.homeTeam, score: game.homeScore)
            }
            Spacer(minLength: 0)
        }
    }
    private func teamColumn(_ team: WidgetTeam, score: String) -> some View {
        VStack(spacing: 4) {
            TeamMark(team: team).frame(width: 35, height: 35)
            Text(team.name).font(.system(size: 11, weight: .bold)).lineLimit(1)
            Text(score).font(.system(size: 20, weight: .black, design: .rounded)).monospacedDigit().opacity(score == "0" ? 0 : 1)
        }.frame(maxWidth: .infinity)
    }
    private var mediumView: some View {
        VStack(alignment: .leading, spacing: 7) {
            header
            if let live = entry.games.first(where: { $0.status == "进行中" }) {
                statusRow(live)
            }
            ForEach(Array(entry.games.prefix(3))) { game in GameLine(game: game) }
            Spacer(minLength: 0)
        }
    }
    private var header: some View {
        HStack {
            Label("今日比赛", systemImage: "basketball.fill").font(.system(size: 13, weight: .black, design: .rounded)).foregroundStyle(Color(red: 1, green: 0.36, blue: 0.36))
            Spacer()
            Text("\(entry.games.count) 场").font(.caption2.bold()).foregroundStyle(.secondary)
        }
    }
    private func statusRow(_ game: WidgetGame) -> some View {
        HStack(spacing: 5) { Circle().fill(.red).frame(width: 6, height: 6); Text(game.time.isEmpty ? "正在进行" : game.time) }
            .font(.caption2.bold()).foregroundStyle(.red)
    }
    private var emptyView: some View {
        VStack(alignment: .leading, spacing: 10) {
            header
            Spacer()
            Image(systemName: "moon.stars.fill").font(.title).foregroundStyle(.secondary)
            Text("今天没有比赛").font(.headline)
            Text("打开 App 查看其他日期").font(.caption).foregroundStyle(.secondary)
            Spacer()
        }
    }
    private var statusColor: Color { .red }
}

struct NBAASSScoreWidget: Widget {
    let kind = "NBAASSScoreWidget"
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: ScoreProvider()) { entry in
            ScoreWidgetView(entry: entry)
                .containerBackground(for: .widget) { Color(red: 0.055, green: 0.063, blue: 0.082) }
                .foregroundStyle(.white)
        }
        .configurationDisplayName("今日比赛")
        .description("快速查看今天的 NBA 比赛、比分与状态。")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

@main
struct NBAASSWidgetBundle: WidgetBundle {
    var body: some Widget { NBAASSScoreWidget() }
}
