import SwiftUI

enum Theme {
    static let background = Color(red: 8/255, green: 9/255, blue: 12/255)
    static let elevated = Color(red: 16/255, green: 18/255, blue: 24/255)
    static let elevated2 = Color(red: 23/255, green: 26/255, blue: 34/255)
    static let ink = Color(red: 242/255, green: 244/255, blue: 247/255)
    static let ink2 = Color(red: 166/255, green: 173/255, blue: 187/255)
    static let ink3 = Color(red: 107/255, green: 114/255, blue: 128/255)
    static let accent = Color(red: 232/255, green: 68/255, blue: 63/255)
    static let cool = Color(red: 61/255, green: 125/255, blue: 250/255)
    static let gold = Color(red: 245/255, green: 183/255, blue: 61/255)
    static let line = Color.white.opacity(0.07)
}

struct AppBackground: View {
    var body: some View {
        Theme.background
            .overlay(alignment: .top) {
                ZStack {
                    RadialGradient(colors: [Theme.accent.opacity(0.18), .clear], center: .topLeading, startRadius: 0, endRadius: 360)
                    RadialGradient(colors: [Theme.cool.opacity(0.14), .clear], center: .topTrailing, startRadius: 0, endRadius: 320)
                }
                .frame(height: 430)
            }
            .ignoresSafeArea()
    }
}

struct AppCardModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .background(
                LinearGradient(colors: [Theme.elevated, Theme.elevated.opacity(0.72)], startPoint: .top, endPoint: .bottom),
                in: RoundedRectangle(cornerRadius: 16, style: .continuous)
            )
            .overlay(RoundedRectangle(cornerRadius: 16, style: .continuous).stroke(Theme.line))
    }
}

extension View {
    func appCard() -> some View { modifier(AppCardModifier()) }
}

struct Eyebrow: View {
    let text: String
    var color: Color = Theme.ink3

    var body: some View {
        Text(text.uppercased())
            .font(.system(size: 11, weight: .bold, design: .rounded))
            .tracking(1.8)
            .foregroundStyle(color)
    }
}

extension Color {
    init(hex: String) {
        let value = UInt64(hex.trimmingCharacters(in: CharacterSet(charactersIn: "#")), radix: 16) ?? 0x8A8F98
        self.init(red: Double((value >> 16) & 255) / 255, green: Double((value >> 8) & 255) / 255, blue: Double(value & 255) / 255)
    }
}
