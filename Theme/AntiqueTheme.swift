import SwiftUI

enum AntiqueTheme {
    static let forest = Color(red: 0.12, green: 0.20, blue: 0.16)
    static let forestLight = Color(red: 0.19, green: 0.29, blue: 0.23)
    static let parchment = Color(red: 0.94, green: 0.90, blue: 0.81)
    static let paper = Color(red: 0.98, green: 0.96, blue: 0.91)
    static let walnut = Color(red: 0.31, green: 0.22, blue: 0.16)
    static let brass = Color(red: 0.63, green: 0.49, blue: 0.25)
    static let ink = Color(red: 0.20, green: 0.17, blue: 0.13)
    static let mutedInk = Color(red: 0.43, green: 0.38, blue: 0.30)

    static func title(_ size: CGFloat) -> Font {
        .system(size: size, weight: .regular, design: .serif)
    }
}

struct PaperBackground: View {
    var body: some View {
        AntiqueTheme.paper.ignoresSafeArea()
    }
}

struct BrassDivider: View {
    var body: some View {
        Rectangle()
            .fill(AntiqueTheme.brass.opacity(0.55))
            .frame(height: 1)
    }
}