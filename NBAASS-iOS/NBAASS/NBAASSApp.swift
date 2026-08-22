import SwiftUI

@main
struct NBAASSApp: App {
    @StateObject private var storage = StorageService()

    init() {
        let appearance = UITabBarAppearance()
        appearance.configureWithTransparentBackground()
        appearance.backgroundEffect = UIBlurEffect(style: .systemUltraThinMaterialDark)
        appearance.backgroundColor = UIColor(Theme.background.opacity(0.82))
        appearance.shadowColor = UIColor.white.withAlphaComponent(0.07)
        UITabBar.appearance().standardAppearance = appearance
        UITabBar.appearance().scrollEdgeAppearance = appearance
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(storage)
                .preferredColorScheme(.dark)
        }
    }
}
