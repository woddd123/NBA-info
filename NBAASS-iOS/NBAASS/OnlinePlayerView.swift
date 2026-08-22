import AVFoundation
import AVKit
import SwiftUI
import WebKit

@MainActor
private final class OnlinePlayerModel: ObservableObject {
    enum Phase: Equatable {
        case searching
        case playing
        case noSource
        case failed
    }

    @Published var phase: Phase = .searching
    @Published var player: AVPlayer?
    @Published var currentSource: URL?

    private var attempted = Set<URL>()
    private var pending: [URL] = []
    private var validating = false
    private var generation = 0
    private var playbackFailureTask: Task<Void, Never>?

    func start(pageURL: URL) {
        generation += 1
        let currentGeneration = generation
        player?.pause()
        playbackFailureTask?.cancel()
        player = nil
        currentSource = nil
        attempted.removeAll()
        pending.removeAll()
        validating = false
        phase = .searching

        Task {
            let urls = await VideoSourceResolver.discover(in: pageURL)
            offer(urls)
        }

        Task {
            try? await Task.sleep(for: .seconds(18))
            guard generation == currentGeneration, phase == .searching else { return }
            phase = .noSource
        }
    }

    func offer(_ urls: [URL]) {
        let fresh = urls
            .filter(VideoSourceResolver.isSupportedMediaURL)
            .filter { !attempted.contains($0) && !pending.contains($0) }
            .sorted { VideoSourceResolver.score($0) > VideoSourceResolver.score($1) }
        pending.append(contentsOf: fresh)
        validateNextIfNeeded()
    }

    func stop() {
        generation += 1
        playbackFailureTask?.cancel()
        player?.pause()
        player = nil
    }

    private func validateNextIfNeeded() {
        guard phase != .playing, !validating, !pending.isEmpty else { return }
        validating = true
        let candidate = pending.removeFirst()
        attempted.insert(candidate)

        Task {
            let asset = AVURLAsset(url: candidate)
            let playable = (try? await asset.load(.isPlayable)) == true
            validating = false
            guard phase != .playing else { return }
            if playable {
                currentSource = candidate
                let item = AVPlayerItem(asset: asset)
                let newPlayer = AVPlayer(playerItem: item)
                player = newPlayer
                phase = .playing
                newPlayer.play()
                observePlaybackFailure(item: item, player: newPlayer)
            } else {
                validateNextIfNeeded()
            }
        }
    }

    private func observePlaybackFailure(item: AVPlayerItem, player activePlayer: AVPlayer) {
        playbackFailureTask?.cancel()
        let currentGeneration = generation
        playbackFailureTask = Task {
            for await _ in NotificationCenter.default.notifications(
                named: .AVPlayerItemFailedToPlayToEndTime,
                object: item
            ) {
                guard !Task.isCancelled,
                      generation == currentGeneration,
                      player === activePlayer else { return }
                activePlayer.pause()
                phase = .failed
                return
            }
        }
    }
}

struct OnlinePlayerView: View {
    @Environment(\.dismiss) private var dismiss
    let link: WatchLink

    @StateObject private var model = OnlinePlayerModel()
    @State private var showNoSourceAlert = false

    private var pageURL: URL? { URL(string: link.url) }

    var body: some View {
        NavigationStack {
            ZStack {
                AppBackground()
                VStack(spacing: 18) {
                    playerSurface

                    VStack(alignment: .leading, spacing: 6) {
                        Text(link.name)
                            .font(.system(size: 21, weight: .bold, design: .rounded))
                            .foregroundStyle(Theme.ink)
                        Text(statusText)
                            .font(.system(size: 13))
                            .foregroundStyle(Theme.ink3)
                            .lineLimit(2)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)

                    if model.phase == .noSource || model.phase == .failed {
                        Button("重新搜索") { beginSearch() }
                            .buttonStyle(.borderedProminent)
                            .tint(Theme.accent)
                    }

                    Spacer()
                }
                .padding(20)

                if let pageURL, model.phase == .searching {
                    VideoSourceProbe(url: pageURL) { model.offer($0) }
                        .frame(width: 1, height: 1)
                        .opacity(0.01)
                        .allowsHitTesting(false)
                        .accessibilityHidden(true)
                }
            }
            .navigationTitle("在线播放")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("关闭") { dismiss() }
                }
            }
        }
        .preferredColorScheme(.dark)
        .onAppear { beginSearch() }
        .onDisappear { model.stop() }
        .onChange(of: model.phase) { _, phase in
            showNoSourceAlert = phase == .noSource
        }
        .alert("无视频源", isPresented: $showNoSourceAlert) {
            Button("重新搜索") { beginSearch() }
            Button("知道了", role: .cancel) {}
        } message: {
            Text("没有找到该网页公开且能由 iPhone 播放的视频源。")
        }
    }

    @ViewBuilder
    private var playerSurface: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(Color.black)
                .aspectRatio(16 / 9, contentMode: .fit)
                .overlay(RoundedRectangle(cornerRadius: 18).stroke(Theme.line))

            if let player = model.player, model.phase == .playing {
                VideoPlayer(player: player)
                    .aspectRatio(16 / 9, contentMode: .fit)
                    .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            } else if model.phase == .searching {
                VStack(spacing: 12) {
                    ProgressView().tint(Theme.accent).scaleEffect(1.2)
                    Text("正在查找视频源…")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(Theme.ink2)
                }
            } else {
                VStack(spacing: 12) {
                    Image(systemName: "video.slash.fill")
                        .font(.system(size: 34))
                        .foregroundStyle(Theme.ink3)
                    Text("无视频源")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundStyle(Theme.ink)
                }
            }
        }
    }

    private var statusText: String {
        switch model.phase {
        case .searching: return "正在分析网页和动态媒体请求，最多等待 18 秒。"
        case .playing: return model.currentSource?.host() ?? "正在播放"
        case .noSource: return "网页未公开可播放的 HLS 或 MP4 视频源。"
        case .failed: return "视频加载失败，请稍后重试。"
        }
    }

    private func beginSearch() {
        guard let pageURL else {
            model.phase = .failed
            return
        }
        model.start(pageURL: pageURL)
    }
}

private enum VideoSourceResolver {
    private static let mediaExtensions = [".m3u8", ".mp4", ".m4v", ".mov"]

    static func isSupportedMediaURL(_ url: URL) -> Bool {
        guard ["http", "https"].contains(url.scheme?.lowercased() ?? "") else { return false }
        let value = url.absoluteString.lowercased()
        return mediaExtensions.contains { value.contains($0) }
    }

    static func score(_ url: URL) -> Int {
        let value = url.absoluteString.lowercased()
        if value.contains(".m3u8") { return 3 }
        if value.contains(".mp4") { return 2 }
        return 1
    }

    static func discover(in pageURL: URL) async -> [URL] {
        if isSupportedMediaURL(pageURL) { return [pageURL] }

        var request = URLRequest(url: pageURL, cachePolicy: .reloadIgnoringLocalCacheData, timeoutInterval: 12)
        request.setValue("text/html,application/xhtml+xml", forHTTPHeaderField: "Accept")
        request.setValue("Mozilla/5.0 (iPhone; CPU iPhone OS 17_0 like Mac OS X) AppleWebKit/605.1.15 Mobile/15E148", forHTTPHeaderField: "User-Agent")

        guard let (data, response) = try? await URLSession.shared.data(for: request),
              let http = response as? HTTPURLResponse,
              (200...299).contains(http.statusCode),
              data.count <= 8_000_000,
              let html = String(data: data, encoding: .utf8) ?? String(data: data, encoding: .isoLatin1) else { return [] }

        return extractURLs(from: html, relativeTo: response.url ?? pageURL)
    }

    static func normalize(_ rawValue: String, relativeTo baseURL: URL) -> URL? {
        let decoded = rawValue
            .replacingOccurrences(of: "\\/", with: "/")
            .replacingOccurrences(of: "\\u0026", with: "&")
            .replacingOccurrences(of: "&amp;", with: "&")
            .trimmingCharacters(in: .whitespacesAndNewlines)

        let url: URL?
        if decoded.hasPrefix("//") {
            url = URL(string: "\(baseURL.scheme ?? "https"):\(decoded)")
        } else {
            url = URL(string: decoded, relativeTo: baseURL)?.absoluteURL
        }
        guard let url, isSupportedMediaURL(url) else { return nil }
        return url
    }

    private static func extractURLs(from html: String, relativeTo baseURL: URL) -> [URL] {
        let normalizedHTML = html.replacingOccurrences(of: "\\/", with: "/")
        let patterns = [
            #"(?i)(?:src|file|url|hls|playurl)\s*[:=]\s*[\"']([^\"']+\.(?:m3u8|mp4|m4v|mov)(?:\?[^\"']*)?)[\"']"#,
            #"(?i)(https?://[^\s\"'<>]+\.(?:m3u8|mp4|m4v|mov)(?:\?[^\s\"'<>]*)?)"#
        ]

        var result: [URL] = []
        var seen = Set<URL>()
        let range = NSRange(normalizedHTML.startIndex..<normalizedHTML.endIndex, in: normalizedHTML)
        for pattern in patterns {
            guard let regex = try? NSRegularExpression(pattern: pattern) else { continue }
            for match in regex.matches(in: normalizedHTML, range: range) {
                let capture = match.numberOfRanges > 1 ? match.range(at: 1) : match.range
                guard let swiftRange = Range(capture, in: normalizedHTML),
                      let url = normalize(String(normalizedHTML[swiftRange]), relativeTo: baseURL),
                      seen.insert(url).inserted else { continue }
                result.append(url)
            }
        }
        return result.sorted { score($0) > score($1) }
    }
}

private struct VideoSourceProbe: UIViewRepresentable {
    let url: URL
    let onSources: ([URL]) -> Void

    func makeCoordinator() -> Coordinator { Coordinator(baseURL: url, onSources: onSources) }

    func makeUIView(context: Context) -> WKWebView {
        let controller = WKUserContentController()
        controller.add(context.coordinator, name: "nbaassVideoSources")
        controller.addUserScript(WKUserScript(source: Self.probeScript, injectionTime: .atDocumentEnd, forMainFrameOnly: false))

        let configuration = WKWebViewConfiguration()
        configuration.userContentController = controller
        configuration.allowsInlineMediaPlayback = true

        let webView = WKWebView(frame: .zero, configuration: configuration)
        webView.navigationDelegate = context.coordinator
        var request = URLRequest(url: url, timeoutInterval: 15)
        request.setValue("Mozilla/5.0 (iPhone; CPU iPhone OS 17_0 like Mac OS X) AppleWebKit/605.1.15 Mobile/15E148", forHTTPHeaderField: "User-Agent")
        webView.load(request)
        return webView
    }

    func updateUIView(_ webView: WKWebView, context: Context) {}

    static func dismantleUIView(_ webView: WKWebView, coordinator: Coordinator) {
        webView.stopLoading()
        webView.configuration.userContentController.removeScriptMessageHandler(forName: "nbaassVideoSources")
    }

    final class Coordinator: NSObject, WKNavigationDelegate, WKScriptMessageHandler {
        let baseURL: URL
        let onSources: ([URL]) -> Void

        init(baseURL: URL, onSources: @escaping ([URL]) -> Void) {
            self.baseURL = baseURL
            self.onSources = onSources
        }

        func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
            guard let values = message.body as? [String] else { return }
            let urls = values.compactMap { VideoSourceResolver.normalize($0, relativeTo: baseURL) }
            if !urls.isEmpty { onSources(urls) }
        }
    }

    private static let probeScript = #"""
    (() => {
      if (window.__nbaassVideoProbe) return;
      window.__nbaassVideoProbe = true;
      const found = new Set();
      const supported = /\.(m3u8|mp4|m4v|mov)(\?|$)/i;
      const add = value => {
        if (!value || typeof value !== 'string') return;
        try {
          const absolute = new URL(value, document.baseURI).href;
          if (supported.test(absolute)) found.add(absolute);
        } catch (_) {}
      };
      const scan = () => {
        document.querySelectorAll('video, video source, source').forEach(node => {
          add(node.currentSrc); add(node.src); add(node.getAttribute('src'));
        });
        performance.getEntriesByType('resource').forEach(entry => add(entry.name));
        if (found.size) window.webkit.messageHandlers.nbaassVideoSources.postMessage([...found]);
      };
      new MutationObserver(scan).observe(document.documentElement, { childList: true, subtree: true, attributes: true, attributeFilter: ['src'] });
      setInterval(scan, 1000);
      scan();
    })();
    """#
}
