import SwiftUI

struct PageHeader: View {
    let eyebrow: String
    let title: String
    var refreshing = false
    var refresh: (() -> Void)?

    var body: some View {
        HStack(alignment: .bottom) {
            VStack(alignment: .leading, spacing: 5) {
                Eyebrow(text: eyebrow)
                Text(title)
                    .font(.system(size: 32, weight: .black, design: .rounded))
                    .foregroundStyle(Theme.ink)
            }
            Spacer()
            if let refresh {
                Button(action: refresh) {
                    Image(systemName: "arrow.clockwise")
                        .font(.system(size: 16, weight: .semibold))
                        .rotationEffect(refreshing ? .degrees(360) : .zero)
                        .animation(refreshing ? .linear(duration: 0.9).repeatForever(autoreverses: false) : .default, value: refreshing)
                        .frame(width: 38, height: 38)
                        .background(Theme.elevated2, in: Circle())
                }
                .disabled(refreshing)
                .accessibilityLabel("刷新")
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 12)
        .padding(.bottom, 12)
    }
}

struct TeamLogo: View {
    let team: Team
    var size: CGFloat = 38

    var body: some View {
        ZStack {
            Circle().fill(TeamCatalog.color(team.abbreviation).opacity(0.18))
            Text(team.abbreviation).font(.system(size: size * 0.25, weight: .black, design: .rounded)).foregroundStyle(TeamCatalog.color(team.abbreviation))
            if let assetName = TeamCatalog.logoAssetName(team.abbreviation) {
                Image(assetName).resizable().scaledToFit()
                    .padding(size * 0.09)
            }
        }
        .frame(width: size, height: size)
    }
}

struct EmptyState: View {
    let title: String
    let hint: String

    var body: some View {
        VStack(spacing: 10) {
            Image(systemName: "basketball").font(.system(size: 28)).foregroundStyle(Theme.ink3)
            Text(title).font(.headline).foregroundStyle(Theme.ink)
            Text(hint).font(.system(size: 13)).multilineTextAlignment(.center).foregroundStyle(Theme.ink3)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 42)
        .appCard()
    }
}

struct GameCard: View {
    let game: Game
    private var live: Bool { game.status == "进行中" }
    private var final: Bool { game.status == "已结束" }
    private var awayWon: Bool { final && (Int(game.awayScore) ?? 0) > (Int(game.homeScore) ?? 0) }
    private var homeWon: Bool { final && (Int(game.homeScore) ?? 0) > (Int(game.awayScore) ?? 0) }

    var body: some View {
        VStack(spacing: 12) {
            HStack {
                if live { Circle().fill(Color.red).frame(width: 6, height: 6) }
                Eyebrow(text: live ? "LIVE · 进行中" : final ? "FINAL · 已结束" : "未开始", color: live ? .red : Theme.ink3)
                Spacer()
                Text(game.time).font(.caption.monospacedDigit()).foregroundStyle(Theme.ink3)
            }
            teamRow(game.awayTeam, score: game.awayScore, label: "客", won: awayWon)
            Rectangle().fill(Theme.line).frame(height: 1)
            teamRow(game.homeTeam, score: game.homeScore, label: "主", won: homeWon)
        }
        .padding(17)
        .background {
            ZStack {
                LinearGradient(colors: [TeamCatalog.color(game.awayTeam.abbreviation).opacity(0.2), .clear, TeamCatalog.color(game.homeTeam.abbreviation).opacity(0.2)], startPoint: .leading, endPoint: .trailing)
                Theme.elevated.opacity(0.72)
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(Theme.line))
    }

    private func teamRow(_ team: Team, score: String, label: String, won: Bool) -> some View {
        HStack(spacing: 12) {
            TeamLogo(team: team)
            VStack(alignment: .leading, spacing: 3) {
                Text(team.name).font(.system(size: 15, weight: .semibold)).foregroundStyle(final && !won ? Theme.ink3 : Theme.ink)
                Text(label).font(.system(size: 10)).tracking(2).foregroundStyle(Theme.ink3)
            }
            Spacer()
            if won { Image(systemName: "triangle.fill").font(.system(size: 8)).rotationEffect(.degrees(90)).foregroundStyle(Theme.accent) }
            Text(score).font(.system(size: 31, weight: .black, design: .rounded).monospacedDigit()).foregroundStyle(final && !won ? Theme.ink3 : Theme.ink)
        }
    }
}

struct LoadingCards: View {
    var count = 3
    var height: CGFloat = 145
    var body: some View {
        VStack(spacing: 12) {
            ForEach(0..<count, id: \.self) { _ in RoundedRectangle(cornerRadius: 16).fill(Theme.elevated2).frame(height: height) }
        }
        .redacted(reason: .placeholder)
    }
}
