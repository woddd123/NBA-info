import SwiftUI

struct RootView: View {
    var body: some View {
        ZStack {
            AppBackground()
            TabView {
                ScheduleView().tabItem { Label("赛程", systemImage: "calendar") }
                RankingsView().tabItem { Label("排名", systemImage: "chart.bar.fill") }
                PlayersView().tabItem { Label("球员", systemImage: "person.fill") }
                SettingsView().tabItem { Label("设置", systemImage: "slider.horizontal.3") }
            }
            .tint(Theme.accent)
        }
    }
}
