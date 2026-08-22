import SwiftUI
import WidgetKit

@MainActor
final class ScheduleViewModel: ObservableObject {
    @Published var date = Calendar.current.startOfDay(for: Date())
    @Published var games: [Game] = []
    @Published var loading = false
    @Published var error: String?

    func load(reload: Bool = false) async {
        loading = true; error = nil
        do {
            games = try await NBAService.games(on: date, reload: reload)
            if Calendar.current.isDateInToday(date) {
                WidgetGameCache.save(games)
                WidgetCenter.shared.reloadTimelines(ofKind: "NBAASSScoreWidget")
            }
        }
        catch { games = []; self.error = error.localizedDescription }
        loading = false
    }
}

struct ScheduleView: View {
    @EnvironmentObject private var storage: StorageService
    @StateObject private var model = ScheduleViewModel()

    private var days: [Date] { (-3...3).compactMap { Calendar.current.date(byAdding: .day, value: $0, to: model.date) } }

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVStack(spacing: 0) {
                    PageHeader(eyebrow: "NBA · Scoreboard", title: "赛程战报", refreshing: model.loading) { Task { await model.load(reload: true) } }
                    dayStrip
                    VStack(alignment: .leading, spacing: 12) {
                        HStack { Eyebrow(text: Calendar.current.isDateInToday(model.date) ? "今日比赛" : model.date.dayKey); Spacer(); if !model.loading { Text("\(model.games.count) 场").font(.caption).foregroundStyle(Theme.ink3) } }
                        if model.loading { LoadingCards() }
                        else if let error = model.error { EmptyState(title: "赛程加载失败", hint: error) }
                        else if model.games.isEmpty { EmptyState(title: "这天没有比赛", hint: "换个日期看看，或者回到今天。") }
                        else { ForEach(model.games) { GameCard(game: $0) } }
                        watchLinks
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 12)
                    .padding(.bottom, 30)
                }
            }
            .background(Color.clear)
            .task { await model.load() }
        }
    }

    private var dayStrip: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(days, id: \.self) { day in
                    Button {
                        model.date = day
                        Task { await model.load() }
                    } label: {
                        VStack(spacing: 2) {
                            Text(Date.weekdayFormatter.string(from: day)).font(.system(size: 10))
                            Text("\(Calendar.current.component(.day, from: day))").font(.system(size: 21, weight: .black, design: .rounded))
                            Circle().fill(.white).frame(width: 4, height: 4).opacity(Calendar.current.isDateInToday(day) ? 0.85 : 0)
                        }
                        .frame(width: 54, height: 62)
                        .foregroundStyle(Calendar.current.isDate(day, inSameDayAs: model.date) ? .white : Theme.ink3)
                        .background(Calendar.current.isDate(day, inSameDayAs: model.date) ? Theme.accent : Theme.elevated, in: RoundedRectangle(cornerRadius: 14))
                        .overlay(RoundedRectangle(cornerRadius: 14).stroke(Calendar.current.isDate(day, inSameDayAs: model.date) ? .clear : Theme.line))
                    }
                }
            }.padding(.horizontal, 20).padding(.vertical, 4)
        }
    }

    private var watchLinks: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack { Eyebrow(text: "观赛入口"); Spacer(); NavigationLink("管理") { LinksView() }.font(.system(size: 13)).foregroundStyle(Theme.cool) }
            if storage.links.isEmpty { EmptyState(title: "还没有观赛链接", hint: "前往管理页面添加常用入口。") }
            else {
                LazyVGrid(columns: [.init(.flexible()), .init(.flexible())], spacing: 12) {
                    ForEach(Array(storage.links.enumerated()), id: \.element.id) { index, link in
                        if let url = URL(string: link.url) {
                            Link(destination: url) {
                                VStack(alignment: .leading, spacing: 5) {
                                    Text(String(format: "%02d", index + 1)).font(.caption.bold().monospacedDigit()).foregroundStyle(Theme.ink3)
                                    Text(link.name).font(.system(size: 15, weight: .semibold)).lineLimit(1).foregroundStyle(Theme.ink)
                                    Text(url.host() ?? link.url).font(.system(size: 11)).lineLimit(1).foregroundStyle(Theme.ink3)
                                }.frame(maxWidth: .infinity, alignment: .leading).padding(14).appCard()
                            }
                        }
                    }
                }
            }
        }.padding(.top, 22)
    }
}
