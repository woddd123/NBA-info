import SwiftUI

private enum PlayerRankingMetric: String, CaseIterable, Identifiable {
    case points, rebounds, assists, steals, blocks, fieldGoalPct, threePointPct, freeThrowPct, minutes

    var id: Self { self }
    var title: String {
        switch self {
        case .points: "得分"
        case .rebounds: "篮板"
        case .assists: "助攻"
        case .steals: "抢断"
        case .blocks: "盖帽"
        case .fieldGoalPct: "投篮命中率"
        case .threePointPct: "三分命中率"
        case .freeThrowPct: "罚球命中率"
        case .minutes: "上场时间"
        }
    }
    var shortTitle: String { self == .minutes ? "分钟" : title }
    var isPercentage: Bool { [.fieldGoalPct, .threePointPct, .freeThrowPct].contains(self) }
    func value(_ stats: Player.PlayerStats) -> Double {
        switch self {
        case .points: stats.points
        case .rebounds: stats.rebounds
        case .assists: stats.assists
        case .steals: stats.steals
        case .blocks: stats.blocks
        case .fieldGoalPct: stats.fieldGoalPct
        case .threePointPct: stats.threePointPct
        case .freeThrowPct: stats.freeThrowPct
        case .minutes: stats.minutes
        }
    }
    func formatted(_ value: Double) -> String {
        isPercentage ? String(format: "%.1f%%", value) : String(format: "%.1f", value)
    }
    func isQualified(_ stats: Player.PlayerStats) -> Bool {
        switch self {
        case .fieldGoalPct: stats.fieldGoalsMade >= 300
        case .threePointPct: stats.threePointersMade >= 82
        case .freeThrowPct: stats.freeThrowsMade >= 125
        default: stats.gamesPlayed >= 58
        }
    }
}

@MainActor
private final class PlayersViewModel: ObservableObject {
    @Published var players: [Player] = []
    @Published var loading = false
    @Published var error: String?

    func load(reload: Bool = false) async {
        loading = true
        error = nil
        do { players = try await NBAService.players(reload: reload) }
        catch { self.error = error.localizedDescription }
        loading = false
    }
}

struct PlayersView: View {
    @StateObject private var model = PlayersViewModel()
    @State private var search = ""
    @State private var metric: PlayerRankingMetric = .points

    private var seasonLabel: String {
        guard let season = model.players.compactMap(\.stats?.season).first else { return "" }
        return "\(season - 1)–\(String(season).suffix(2)) 常规赛"
    }

    private var rankedPlayers: [Player] {
        model.players.filter { player in
            guard let stats = player.stats, metric.isQualified(stats) else { return false }
            guard !search.isEmpty else { return true }
            return player.fullName.localizedCaseInsensitiveContains(search) ||
            player.team?.abbreviation.localizedCaseInsensitiveContains(search) == true ||
            TeamCatalog.info(player.team?.abbreviation ?? "")?.name.contains(search) == true
        }.sorted { lhs, rhs in
            guard let left = lhs.stats, let right = rhs.stats else { return false }
            let leftValue = metric.value(left), rightValue = metric.value(right)
            return leftValue == rightValue ? lhs.fullName < rhs.fullName : leftValue > rightValue
        }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 12) {
                    PageHeader(eyebrow: "NBA · Players", title: "球员数据", refreshing: model.loading) {
                        Task { await model.load(reload: true) }
                    }
                    if !seasonLabel.isEmpty {
                        Text(seasonLabel)
                            .font(.system(size: 12, weight: .semibold)).foregroundStyle(Theme.ink3)
                            .padding(.horizontal, 20).padding(.bottom, 2)
                    }
                    if model.loading && model.players.isEmpty {
                        LoadingCards(count: 6, height: 72).padding(.horizontal, 20)
                    } else if let error = model.error, model.players.isEmpty {
                        EmptyState(title: "暂无球员数据", hint: error).padding(.horizontal, 20)
                    } else {
                        rankingFilter
                        HStack {
                            Text("\(metric.title)榜")
                                .font(.system(size: 13, weight: .semibold)).foregroundStyle(Theme.ink)
                            Spacer()
                            Text("\(rankedPlayers.count) 名符合排名资格")
                                .font(.system(size: 11)).foregroundStyle(Theme.ink3)
                        }.padding(.horizontal, 20)
                        LazyVStack(spacing: 0) {
                            ForEach(Array(rankedPlayers.enumerated()), id: \.element.id) { index, player in
                                playerRow(player, rank: index + 1)
                                if player.id != rankedPlayers.last?.id {
                                    Rectangle().fill(Theme.line).frame(height: 1).padding(.leading, 64)
                                }
                            }
                        }
                        .appCard()
                        .padding(.horizontal, 20)
                    }
                }
                .padding(.bottom, 30)
            }
            .searchable(text: $search, prompt: "搜索球员或球队")
            .background(Color.clear)
            .task { if model.players.isEmpty { await model.load() } }
        }
    }

    private var rankingFilter: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(PlayerRankingMetric.allCases) { item in
                    Button {
                        withAnimation(.easeOut(duration: 0.18)) { metric = item }
                    } label: {
                        Text(item.title)
                            .font(.system(size: 12, weight: item == metric ? .semibold : .regular))
                            .foregroundStyle(item == metric ? Color.black : Theme.ink2)
                            .padding(.horizontal, 14).frame(height: 34)
                            .background(item == metric ? Theme.accent : Theme.elevated2, in: Capsule())
                    }.buttonStyle(.plain)
                }
            }.padding(.horizontal, 20)
        }
    }

    private func playerRow(_ player: Player, rank: Int) -> some View {
        HStack(spacing: 12) {
            Text("\(rank)")
                .font(.system(size: 12, weight: rank <= 3 ? .bold : .medium, design: .rounded))
                .foregroundStyle(rank <= 3 ? Theme.accent : Theme.ink3)
                .frame(width: 24)
            playerHeadshot(player)
            VStack(alignment: .leading, spacing: 4) {
                Text(player.fullName).font(.system(size: 15, weight: .semibold)).foregroundStyle(Theme.ink)
                let teamName = TeamCatalog.info(player.team?.abbreviation ?? "")?.name ?? player.team?.abbreviation ?? "自由球员"
                Text([teamName, player.position.isEmpty ? nil : player.position, player.jerseyNumber.isEmpty ? nil : "#\(player.jerseyNumber)"].compactMap { $0 }.joined(separator: " · "))
                    .font(.system(size: 11)).foregroundStyle(Theme.ink3)
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 3) {
                if let stats = player.stats {
                    Text(metric.formatted(metric.value(stats)))
                        .font(.system(size: 16, weight: .bold, design: .rounded).monospacedDigit())
                        .foregroundStyle(Theme.ink)
                    Text(metric.isPercentage ? metric.shortTitle : "场均\(metric.shortTitle)")
                        .font(.system(size: 9)).foregroundStyle(Theme.ink3)
                }
            }
        }
        .padding(.horizontal, 14).padding(.vertical, 11)
    }

    @ViewBuilder
    private func playerHeadshot(_ player: Player) -> some View {
        AsyncImage(url: URL(string: player.headshot)) { phase in
            switch phase {
            case .success(let image):
                image.resizable().scaledToFill()
            case .empty:
                ProgressView().controlSize(.small).tint(Theme.ink3)
            case .failure:
                playerHeadshotFallback(player)
            @unknown default:
                playerHeadshotFallback(player)
            }
        }
        .frame(width: 44, height: 44)
        .background(Theme.elevated2)
        .clipShape(Circle())
        .overlay(Circle().stroke(Theme.line, lineWidth: 1))
    }

    @ViewBuilder
    private func playerHeadshotFallback(_ player: Player) -> some View {
        if let abbreviation = player.team?.abbreviation {
            TeamLogo(team: TeamCatalog.team(abbreviation), size: 40)
        } else {
            Text(String(player.firstName.prefix(1)) + String(player.lastName.prefix(1)))
                .font(.caption.bold()).foregroundStyle(Theme.ink3)
        }
    }
}
