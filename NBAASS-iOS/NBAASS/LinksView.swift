import SwiftUI

struct LinksView: View {
    @EnvironmentObject private var storage: StorageService
    @State private var showingForm = false
    @State private var editing: WatchLink?
    @State private var deleteTarget: WatchLink?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                HStack { Eyebrow(text: "Watch · Links"); Spacer(); Button { editing = nil; showingForm = true } label: { Label("添加", systemImage: "plus") }.font(.system(size: 13, weight: .semibold)).foregroundStyle(Theme.cool) }
                Text("观赛入口").font(.system(size: 32, weight: .black, design: .rounded))
                if storage.links.isEmpty { EmptyState(title: "还没有观赛链接", hint: "点击右上角添加常用平台。") }
                ForEach(Array(storage.links.enumerated()), id: \.element.id) { index, link in
                    HStack(spacing: 14) {
                        Text(String(format: "%02d", index + 1)).font(.system(size: 14, weight: .black, design: .rounded).monospacedDigit()).foregroundStyle(Theme.ink3)
                        VStack(alignment: .leading, spacing: 4) { Text(link.name).font(.system(size: 15, weight: .semibold)); Text(link.url).font(.system(size: 11)).lineLimit(1).foregroundStyle(Theme.ink3) }
                        Spacer()
                        Button { editing = link; showingForm = true } label: { Image(systemName: "pencil") }.buttonStyle(.borderless).foregroundStyle(Theme.ink2)
                        Button { deleteTarget = link } label: { Image(systemName: "trash") }.buttonStyle(.borderless).foregroundStyle(Theme.accent)
                    }.padding(15).appCard()
                }
            }.padding(20)
        }
        .background(AppBackground())
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showingForm) { LinkFormView(link: editing) }
        .alert("删除链接", isPresented: Binding(get: { deleteTarget != nil }, set: { if !$0 { deleteTarget = nil } })) {
            Button("取消", role: .cancel) {}
            Button("删除", role: .destructive) { if let target = deleteTarget { storage.links.removeAll { $0.id == target.id } }; deleteTarget = nil }
        } message: { Text("确定删除“\(deleteTarget?.name ?? "")”吗？") }
    }
}

private struct LinkFormView: View {
    @EnvironmentObject private var storage: StorageService
    @Environment(\.dismiss) private var dismiss
    let link: WatchLink?
    @State private var name = ""
    @State private var url = ""
    @State private var error = ""

    var body: some View {
        NavigationStack {
            Form {
                Section("平台信息") {
                    TextField("平台名称", text: $name)
                    TextField("https://example.com", text: $url).textInputAutocapitalization(.never).keyboardType(.URL).autocorrectionDisabled()
                }
                if !error.isEmpty { Text(error).foregroundStyle(.red) }
            }
            .navigationTitle(link == nil ? "添加入口" : "编辑入口")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("取消") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) { Button("保存", action: save) }
            }
            .onAppear { name = link?.name ?? ""; url = link?.url ?? "" }
        }
    }

    private func save() {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedURL = url.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty else { error = "请填写平台名称"; return }
        guard let parsed = URL(string: trimmedURL), ["http", "https"].contains(parsed.scheme?.lowercased() ?? "") else { error = "网址需要以 http:// 或 https:// 开头"; return }
        if let link, let index = storage.links.firstIndex(where: { $0.id == link.id }) { storage.links[index].name = trimmedName; storage.links[index].url = trimmedURL }
        else { storage.links.append(WatchLink(name: trimmedName, url: trimmedURL)) }
        dismiss()
    }
}
