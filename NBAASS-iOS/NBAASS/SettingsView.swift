import SwiftUI

struct SettingsView: View {
    @EnvironmentObject private var storage: StorageService
    @State private var showReset = false
    @State private var toast = ""

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    PageHeader(eyebrow: "App · Settings", title: "设置").padding(.horizontal, -20)
                    NavigationLink { LinksView() } label: {
                        settingRow(icon: "link", title: "观赛链接管理", detail: "添加、编辑你自己的观赛入口")
                    }.buttonStyle(.plain).appCard()

                    section(title: "数据服务") {
                        Text("赛事优先读取实时缓存，历史比赛、排名和球员数据由数据库持久化；缓存失效时由服务端自动更新，无需在设备上填写 API Key。")
                            .font(.system(size: 12)).foregroundStyle(Theme.ink3).lineSpacing(4).padding(16)
                    }

                    section(title: "存储") {
                        VStack(spacing: 0) {
                            Button { storage.clearCache(); flash("接口缓存已清理") } label: { settingRow(icon: "arrow.clockwise", title: "清理接口缓存", detail: "只清设备本地缓存，服务端数据不会删除") }.buttonStyle(.plain)
                            Rectangle().fill(Theme.line).frame(height: 1)
                            Button { showReset = true } label: { settingRow(icon: "trash", title: "重置全部数据", detail: "清空观赛链接和设备本地缓存", danger: true) }.buttonStyle(.plain)
                        }
                    }

                    section(title: "关于原生版") {
                        VStack(alignment: .leading, spacing: 14) {
                            step(1, "在 Xcode 中选择 iPhone 设备或模拟器")
                            step(2, "按下运行按钮安装应用")
                            step(3, "数据和设置将安全保存在当前设备")
                        }.padding(16)
                    }

                    VStack(spacing: 8) {
                        Image("BrandIcon").resizable().frame(width: 56, height: 56).clipShape(RoundedRectangle(cornerRadius: 13))
                        Text("NBA 赛事数据助手").font(.system(size: 15, weight: .semibold))
                        Text("v1.0.0 · iOS Native").font(.system(size: 11).monospacedDigit()).foregroundStyle(Theme.ink3)
                        Text("个人自用的数据展示工具。数据来自公开 API，不存储、不分发任何版权内容。")
                            .font(.system(size: 11)).multilineTextAlignment(.center).foregroundStyle(Theme.ink3).padding(.top, 6)
                    }.padding(.vertical, 18).padding(.horizontal, 30)
                }.padding(.horizontal, 20).padding(.bottom, 24)
            }.background(Color.clear)
            .alert("重置全部数据", isPresented: $showReset) {
                Button("取消", role: .cancel) {}
                Button("重置", role: .destructive) { storage.reset() }
            } message: { Text("将清空观赛链接和设备本地缓存。") }
        }
    }

    private func section<Content: View>(title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(spacing: 0) {
            Text(title).font(.system(size: 12, weight: .semibold)).foregroundStyle(Theme.ink2).frame(maxWidth: .infinity, alignment: .leading).padding(.horizontal, 16).padding(.vertical, 11).background(Color.white.opacity(0.015))
            Rectangle().fill(Theme.line).frame(height: 1)
            content()
        }.appCard().clipShape(RoundedRectangle(cornerRadius: 16))
    }

    private func settingRow(icon: String, title: String, detail: String, danger: Bool = false) -> some View {
        HStack(spacing: 14) {
            Image(systemName: icon).frame(width: 34, height: 34).background(Theme.elevated2, in: RoundedRectangle(cornerRadius: 10)).foregroundStyle(danger ? Theme.accent : Theme.ink2)
            VStack(alignment: .leading, spacing: 3) { Text(title).font(.system(size: 15, weight: .semibold)).foregroundStyle(danger ? Theme.accent : Theme.ink); Text(detail).font(.system(size: 11)).foregroundStyle(Theme.ink3) }
            Spacer(); Image(systemName: "chevron.right").font(.caption.bold()).foregroundStyle(Theme.ink3)
        }.padding(16)
    }

    private func step(_ number: Int, _ text: String) -> some View {
        HStack(spacing: 12) { Text("\(number)").font(.caption.bold()).frame(width: 24, height: 24).background(Theme.elevated2, in: Circle()).foregroundStyle(Theme.accent); Text(text).font(.system(size: 14)).foregroundStyle(Theme.ink2) }
    }

    private func flash(_ message: String) {
        toast = message
        Task { try? await Task.sleep(for: .seconds(2)); toast = "" }
    }
}
