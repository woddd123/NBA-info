import SwiftUI
import Charts

@MainActor
final class RankingsViewModel: ObservableObject {
    @Published var teams: [Team] = []
    @Published var seasonLabel = ""
    @Published var loading = false
    @Published var error: String?

    func load(reload: Bool = false) async {
        loading = true; error = nil
        do {
            let result = try await NBAService.standings(reload: reload)
            teams = result.teams
            seasonLabel = result.seasonLabel
        }
        catch { teams = []; self.error = error.localizedDescription }
        loading = false
    }
}

struct RankingsView: View {
    enum Section: String, CaseIterable { case east = "东部", west = "西部", playoffs = "季后赛" }
    @StateObject private var model = RankingsViewModel()
    @State private var section = Section.east

    private var selectedTeams: [Team] {
        model.teams.filter { $0.conference == (section == .west ? "West" : "East") }.sorted { $0.winRate > $1.winRate }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVStack(spacing: 0) {
                    PageHeader(eyebrow: "NBA · Standings", title: "球队排名", refreshing: model.loading) { Task { await model.load(reload: true) } }
                    if !model.seasonLabel.isEmpty {
                        Text("\(model.seasonLabel) 常规赛")
                            .font(.system(size: 12, weight: .semibold)).foregroundStyle(Theme.ink3)
                            .padding(.horizontal, 20).padding(.bottom, 10)
                    }
                    Picker("排名类别", selection: $section) { ForEach(Section.allCases, id: \.self) { Text($0.rawValue).tag($0) } }
                        .pickerStyle(.segmented).padding(.horizontal, 20)
                    if section == .playoffs { PlayoffsView() }
                    else { regularSeason }
                }
            }
            .background(Color.clear)
            .task { await model.load() }
        }
    }

    private var regularSeason: some View {
        VStack(alignment: .leading, spacing: 18) {
            if model.loading { LoadingCards(count: 5, height: 75) }
            else if let error = model.error { EmptyState(title: "暂无排名数据", hint: error) }
            else if selectedTeams.isEmpty { EmptyState(title: "暂无排名数据", hint: "点右上角刷新重试。") }
            else {
                VStack(alignment: .leading, spacing: 12) {
                    HStack { Eyebrow(text: "前八胜率"); Spacer(); Text("按球队配色").font(.system(size: 10)).foregroundStyle(Theme.ink3) }
                    Chart(Array(selectedTeams.prefix(8))) { team in
                        BarMark(x: .value("球队", team.abbreviation), y: .value("胜率", team.winRate))
                            .foregroundStyle(TeamCatalog.color(team.abbreviation)).cornerRadius(3)
                    }
                    .chartYScale(domain: 0...1)
                    .chartYAxis { AxisMarks { value in AxisGridLine().foregroundStyle(Theme.line); AxisValueLabel { if let number = value.as(Double.self) { Text("\(Int(number * 100))%") } } } }
                    .frame(height: 188)
                }.padding(16).appCard()

                Eyebrow(text: "完整排名")
                LazyVStack(spacing: 0) {
                    ForEach(Array(selectedTeams.enumerated()), id: \.element.id) { index, team in
                        if index == 6 || index == 10 { cutline(index == 6 ? "季后赛分界" : "附加赛分界") }
                        standingRow(index: index, team: team)
                        if index != selectedTeams.count - 1 { Rectangle().fill(Theme.line).frame(height: 1).padding(.leading, 52) }
                    }
                }.appCard()
            }
        }.padding(20)
    }

    private func standingRow(index: Int, team: Team) -> some View {
        HStack(spacing: 12) {
            Text("\(index + 1)").font(.system(size: 17, weight: .black, design: .rounded).monospacedDigit()).frame(width: 22).foregroundStyle(index < 6 ? Theme.ink : Theme.ink3)
            TeamLogo(team: team, size: 32)
            VStack(alignment: .leading, spacing: 6) {
                Text(team.name).font(.system(size: 15, weight: .semibold)).foregroundStyle(Theme.ink)
                GeometryReader { proxy in
                    Capsule().fill(Theme.elevated2).overlay(alignment: .leading) { Capsule().fill(TeamCatalog.color(team.abbreviation)).frame(width: proxy.size.width * team.winRate) }
                }.frame(height: 3)
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 3) {
                Text("\(Int(team.wins))-\(Int(team.losses))").font(.system(size: 17, weight: .black, design: .rounded).monospacedDigit()).foregroundStyle(Theme.ink)
                Text(String(format: "%.1f%%  %@", team.winRate * 100, team.streak)).font(.system(size: 11).monospacedDigit()).foregroundStyle(Theme.ink3)
            }
        }.padding(.horizontal, 14).padding(.vertical, 12)
    }

    private func cutline(_ text: String) -> some View {
        HStack { Rectangle().fill(Theme.line).frame(height: 1); Text(text).font(.system(size: 9)).tracking(2).foregroundStyle(Theme.ink3); Rectangle().fill(Theme.line).frame(height: 1) }.padding(.horizontal, 14).padding(.vertical, 7)
    }
}

@MainActor
private final class PlayoffsViewModel: ObservableObject {
    @Published var bracket: PlayoffBracket?
    @Published var loading = false
    @Published var error: String?
    func load() async {
        loading = true; error = nil
        do { bracket = try await NBAService.playoffs() }
        catch { self.error = error.localizedDescription }
        loading = false
    }
    func wins(_ abbr: String, against other: String) -> Int? {
        bracket?.series.first { series in
            Set(series.teams.map { TeamCatalog.normalize($0.abbreviation) }) == Set([TeamCatalog.normalize(abbr), TeamCatalog.normalize(other)])
        }?.teams.first { TeamCatalog.normalize($0.abbreviation) == TeamCatalog.normalize(abbr) }?.wins
    }
}

private struct PlayoffsView: View {
    @StateObject private var model = PlayoffsViewModel()
    @Environment(\.verticalSizeClass) private var verticalSizeClass
    private let bracketHeight: CGFloat = 256
    private var eastSeeds: [String] { seeds(for: "East") }
    private var westSeeds: [String] { seeds(for: "West") }
    private var eastRounds: [(String, [[String]])] { rounds(for: "East") }
    private var westRounds: [(String, [[String]])] { rounds(for: "West") }
    private var finals: PlayoffSeriesData? { model.bracket?.series.first { $0.round == "nba_finals" } }

    var body: some View {
        Group {
            if model.loading && model.bracket == nil {
                LoadingCards(count: 4, height: 72).padding(20)
            } else if let error = model.error, model.bracket == nil {
                EmptyState(title: "暂无季后赛数据", hint: error).padding(20)
            } else if verticalSizeClass == .compact {
                landscapeBracket
            } else {
                portraitBracket
            }
        }
        .task { if model.bracket == nil { await model.load() } }
    }

    private func seeds(for conference: String) -> [String] {
        (model.bracket?.series.filter { $0.conference == conference && $0.round == "first_round" }.flatMap(\.teams) ?? [])
            .sorted { ($0.seed ?? 99) < ($1.seed ?? 99) }.map(\.abbreviation)
    }

    private func rounds(for conference: String) -> [(String, [[String]])] {
        let definitions = [("first_round", "首轮 · FIRST ROUND"), ("semifinals", "分区半决赛 · SEMIFINALS"), ("conference_finals", "分区决赛 · CONF FINALS")]
        return definitions.map { key, title in
            let pairs = model.bracket?.series.filter { $0.conference == conference && $0.round == key }
                .sorted { ($0.teams.compactMap(\.seed).min() ?? 99) < ($1.teams.compactMap(\.seed).min() ?? 99) }
                .map { $0.teams.map(\.abbreviation) } ?? []
            return (title, pairs)
        }
    }

    private var portraitBracket: some View {
        VStack(alignment: .leading, spacing: 26) {
            VStack(alignment: .leading, spacing: 4) { Text("\(model.bracket?.seasonDisplay ?? "最近赛季") PLAYOFFS").font(.system(size: 26, weight: .black, design: .rounded)); Text(model.loading ? "正在同步系列赛比分…" : "季后赛对阵").font(.system(size: 11)).foregroundStyle(Theme.ink3) }
            conference("EASTERN", color: Theme.accent, rounds: eastRounds, seeds: eastSeeds)
            HStack { Rectangle().fill(Theme.line).frame(height: 1); Text("NBA FINALS").font(.system(size: 13, weight: .black, design: .rounded)).tracking(3).foregroundStyle(Theme.gold); Rectangle().fill(Theme.line).frame(height: 1) }
            if let finals, finals.teams.count == 2 { seriesCard(finals.teams.map(\.abbreviation), seeds: finals.teams.map(\.abbreviation)) }
            conference("WESTERN", color: Theme.cool, rounds: westRounds, seeds: westSeeds)
        }.padding(20)
    }

    private var landscapeBracket: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack(alignment: .firstTextBaseline) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("\(model.bracket?.seasonDisplay ?? "最近赛季") PLAYOFFS").font(.system(size: 23, weight: .black, design: .rounded))
                    Text(model.loading ? "正在同步系列赛比分…" : "横屏对阵轮次图").font(.system(size: 10)).foregroundStyle(Theme.ink3)
                }
                Spacer()
                Label("左右滑动浏览完整对阵", systemImage: "arrow.left.and.right").font(.system(size: 10)).foregroundStyle(Theme.ink3)
            }

            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Label("EAST", systemImage: "e.square.fill").foregroundStyle(Theme.accent)
                    Spacer()
                    Text("NBA PLAYOFF BRACKET").foregroundStyle(Theme.gold)
                    Spacer()
                    Label("WEST", systemImage: "w.square.fill").foregroundStyle(Theme.cool)
                }
                .font(.system(size: 11, weight: .black, design: .rounded))
                .tracking(1.5)

                ScrollView(.horizontal, showsIndicators: true) {
                    HStack(spacing: 0) {
                        landscapeRound(eastRounds[0], seeds: eastSeeds)
                        connector(from: 4, to: 2)
                        landscapeRound(eastRounds[1], seeds: eastSeeds)
                        connector(from: 2, to: 1)
                        landscapeRound(eastRounds[2], seeds: eastSeeds)
                        finalsConnector(mirrored: false)
                        championshipColumn
                            .id("NBA-FINALS")
                        finalsConnector(mirrored: true)
                        landscapeRound(westRounds[2], seeds: westSeeds)
                        connector(from: 2, to: 1, mirrored: true)
                        landscapeRound(westRounds[1], seeds: westSeeds)
                        connector(from: 4, to: 2, mirrored: true)
                        landscapeRound(westRounds[0], seeds: westSeeds)
                    }
                    .padding(.horizontal, 10)
                    .padding(.bottom, 6)
                }
                .defaultScrollAnchor(.center)
            }
            .padding(13)
            .appCard()
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 14)
    }

    private func connector(from: Int, to: Int, mirrored: Bool = false) -> some View {
        VStack(spacing: 7) {
            Color.clear.frame(height: 13)
            BracketConnector(fromCount: from, toCount: to)
                .scaleEffect(x: mirrored ? -1 : 1, y: 1)
                .frame(width: 42, height: bracketHeight)
        }
    }

    private func finalsConnector(mirrored: Bool) -> some View {
        VStack(spacing: 7) {
            Color.clear.frame(height: 13)
            HStack(spacing: 0) {
                Rectangle().fill(Theme.ink3.opacity(0.62)).frame(height: 1.2)
                Image(systemName: "chevron.right")
                    .font(.system(size: 9, weight: .bold))
                    .foregroundStyle(Theme.gold)
            }
            .scaleEffect(x: mirrored ? -1 : 1, y: 1)
            .frame(width: 42, height: bracketHeight)
        }
    }

    private var championshipColumn: some View {
        let east = finals?.teams.first?.abbreviation
        let west = finals?.teams.dropFirst().first?.abbreviation
        return VStack(spacing: 7) {
            HStack(spacing: 5) {
                Image(systemName: "trophy.fill")
                Eyebrow(text: "NBA 总决赛", color: Theme.gold)
                Image(systemName: "trophy.fill")
            }
            .font(.system(size: 10))
            .foregroundStyle(Theme.gold)

            VStack {
                Spacer()
                ChampionshipCard(
                    east: east.map { TeamCatalog.team($0) },
                    west: west.map { TeamCatalog.team($0) },
                    eastWins: east.flatMap { e in west.flatMap { model.wins(e, against: $0) } },
                    westWins: west.flatMap { w in east.flatMap { model.wins(w, against: $0) } }
                )
                Spacer()
            }
            .frame(width: 180, height: bracketHeight)
        }
    }

    private func landscapeRound(_ round: (String, [[String]]), seeds: [String]) -> some View {
        VStack(spacing: 7) {
            Eyebrow(text: round.0.components(separatedBy: " · ").first ?? round.0)
            ZStack(alignment: .topLeading) {
                ForEach(Array(round.1.enumerated()), id: \.offset) { index, pair in
                    CompactSeriesCard(pair: pair, seeds: seeds, wins1: model.wins(pair[0], against: pair[1]), wins2: model.wins(pair[1], against: pair[0]))
                        .frame(width: 168)
                        .position(
                            x: 84,
                            y: (CGFloat(index) + 0.5) * bracketHeight / CGFloat(round.1.count)
                        )
                }
            }
            .frame(width: 168, height: bracketHeight)
        }
    }

    private func conference(_ title: String, color: Color, rounds: [(String, [[String]])], seeds: [String]) -> some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack { Capsule().fill(color).frame(width: 32, height: 3); Text(title).font(.system(size: 17, weight: .black, design: .rounded)).tracking(2).foregroundStyle(color); Rectangle().fill(Theme.line).frame(height: 1) }
            ForEach(Array(rounds.enumerated()), id: \.offset) { _, round in
                VStack(alignment: .leading, spacing: 10) {
                    Eyebrow(text: round.0)
                    ForEach(Array(round.1.enumerated()), id: \.offset) { _, pair in seriesCard(pair, seeds: seeds) }
                }
            }
        }
    }

    private func seriesCard(_ pair: [String], seeds: [String]) -> some View {
        let wins1 = model.wins(pair[0], against: pair[1])
        let wins2 = model.wins(pair[1], against: pair[0])
        let played = wins1 != nil || wins2 != nil
        return VStack(spacing: 8) {
            HStack { Eyebrow(text: "\((seeds.firstIndex(of: pair[0]) ?? 0) + 1) VS \((seeds.firstIndex(of: pair[1]) ?? 0) + 1)"); Spacer(); Text((wins1 ?? 0) >= 4 || (wins2 ?? 0) >= 4 ? "已结束" : played ? "进行中" : "未开赛").font(.system(size: 10)).foregroundStyle(played ? Theme.accent : Theme.ink3) }
            seriesTeam(pair[0], seed: (seeds.firstIndex(of: pair[0]) ?? 0) + 1, wins: wins1)
            HStack { Rectangle().fill(Theme.line).frame(height: 1); Text(played ? "\(wins1 ?? 0) - \(wins2 ?? 0)" : "VS").font(.caption.bold().monospacedDigit()).foregroundStyle(Theme.ink2); Rectangle().fill(Theme.line).frame(height: 1) }
            seriesTeam(pair[1], seed: (seeds.firstIndex(of: pair[1]) ?? 0) + 1, wins: wins2)
        }.padding(15).appCard()
    }

    private func seriesTeam(_ abbr: String, seed: Int, wins: Int?) -> some View {
        let team = TeamCatalog.team(abbr)
        return HStack { Text("\(seed)").font(.caption.bold()).frame(width: 20).foregroundStyle(Theme.ink3); TeamLogo(team: team, size: 30); Text(team.name).font(.system(size: 15, weight: .medium)).foregroundStyle(Theme.ink2); Spacer(); Text(wins.map(String.init) ?? "–").font(.title3.bold().monospacedDigit()).foregroundStyle(Theme.ink3) }
    }
}

private struct ChampionshipCard: View {
    let east: Team?
    let west: Team?
    let eastWins: Int?
    let westWins: Int?

    var body: some View {
        VStack(spacing: 0) {
            finalist(team: east, fallback: "东部冠军", wins: eastWins, tint: Theme.accent)
            HStack(spacing: 6) {
                Rectangle().fill(Theme.gold.opacity(0.35)).frame(height: 1)
                Text(eastWins != nil || westWins != nil ? "\(eastWins ?? 0) - \(westWins ?? 0)" : "VS")
                    .font(.system(size: 10, weight: .black, design: .rounded).monospacedDigit())
                    .foregroundStyle(Theme.gold)
                Rectangle().fill(Theme.gold.opacity(0.35)).frame(height: 1)
            }
            finalist(team: west, fallback: "西部冠军", wins: westWins, tint: Theme.cool)
        }
        .padding(10)
        .background(
            LinearGradient(colors: [Theme.gold.opacity(0.13), Theme.elevated2], startPoint: .top, endPoint: .bottom),
            in: RoundedRectangle(cornerRadius: 12, style: .continuous)
        )
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Theme.gold.opacity(0.42)))
    }

    private func finalist(team: Team?, fallback: String, wins: Int?, tint: Color) -> some View {
        HStack(spacing: 7) {
            if let team { TeamLogo(team: team, size: 25) }
            else { Image(systemName: "questionmark.circle.fill").font(.system(size: 22)).foregroundStyle(tint.opacity(0.7)) }
            Text(team?.name ?? fallback).font(.system(size: 11, weight: .bold)).foregroundStyle(team == nil ? Theme.ink3 : Theme.ink).lineLimit(1)
            Spacer(minLength: 4)
            Text(wins.map(String.init) ?? "–").font(.system(size: 14, weight: .black, design: .rounded).monospacedDigit()).foregroundStyle(Theme.ink)
        }
        .frame(height: 34)
    }
}

private struct CompactSeriesCard: View {
    let pair: [String]
    let seeds: [String]
    let wins1: Int?
    let wins2: Int?

    var body: some View {
        VStack(spacing: 0) {
            teamLine(pair[0], wins: wins1)
            Rectangle().fill(Theme.line).frame(height: 1)
            teamLine(pair[1], wins: wins2)
        }
        .background(Theme.elevated2.opacity(0.94), in: RoundedRectangle(cornerRadius: 9, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 9).stroke(Theme.line))
    }

    private func teamLine(_ abbr: String, wins: Int?) -> some View {
        let team = TeamCatalog.team(abbr)
        let seed = (seeds.firstIndex(of: abbr) ?? 0) + 1
        let winner = wins == 4
        return HStack(spacing: 7) {
            Text("\(seed)").font(.system(size: 9, weight: .bold).monospacedDigit()).foregroundStyle(Theme.ink3).frame(width: 12)
            TeamLogo(team: team, size: 22)
            Text(team.name).font(.system(size: 11, weight: winner ? .bold : .medium)).foregroundStyle(winner ? Theme.ink : Theme.ink2).lineLimit(1)
            Spacer(minLength: 3)
            Text(wins.map(String.init) ?? "–").font(.system(size: 13, weight: .black, design: .rounded).monospacedDigit()).foregroundStyle(winner ? Theme.ink : Theme.ink3)
        }
        .padding(.horizontal, 8)
        .frame(height: 28)
    }
}

private struct BracketConnector: View {
    let fromCount: Int
    let toCount: Int

    var body: some View {
        Canvas { context, size in
            let inputs = (0..<fromCount).map { (CGFloat($0) + 0.5) * size.height / CGFloat(fromCount) }
            let outputs = (0..<toCount).map { (CGFloat($0) + 0.5) * size.height / CGFloat(toCount) }
            for outputIndex in 0..<toCount {
                let firstInput = outputIndex * 2
                guard firstInput + 1 < inputs.count else { continue }
                let midX = size.width * 0.48
                var path = Path()
                path.move(to: CGPoint(x: 0, y: inputs[firstInput]))
                path.addLine(to: CGPoint(x: midX, y: inputs[firstInput]))
                path.addLine(to: CGPoint(x: midX, y: inputs[firstInput + 1]))
                path.addLine(to: CGPoint(x: 0, y: inputs[firstInput + 1]))
                path.move(to: CGPoint(x: midX, y: outputs[outputIndex]))
                path.addLine(to: CGPoint(x: size.width, y: outputs[outputIndex]))
                context.stroke(path, with: .color(Theme.ink3.opacity(0.62)), lineWidth: 1.2)
            }
        }
        .accessibilityHidden(true)
    }
}
