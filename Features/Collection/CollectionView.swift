import SwiftUI

struct CollectionView: View {
    var body: some View {
        NavigationStack {
            ZStack {
                PaperBackground()
                VStack(spacing: 12) {
                    Image(systemName: "books.vertical")
                        .font(.system(size: 38, weight: .ultraLight))
                        .foregroundStyle(AntiqueTheme.brass)
                    Text("Din samling")
                        .font(AntiqueTheme.title(29))
                        .foregroundStyle(AntiqueTheme.forest)
                    Text("Här sparas dina undersökta föremål när samlingsfunktionen är färdig.")
                        .font(.system(size: 14, design: .serif))
                        .foregroundStyle(AntiqueTheme.mutedInk)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 35)
                }
            }
            .navigationBarHidden(true)
        }
    }
}