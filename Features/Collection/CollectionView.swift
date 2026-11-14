import SwiftUI

struct CollectionView: View {
    var body: some View {
        NavigationStack {
            ZStack {
                PaperBackground()

                VStack(spacing: 18) {
                    Image(systemName: "books.vertical")
                        .font(.system(size: 42, weight: .ultraLight))
                        .foregroundStyle(AntiqueTheme.brass)

                    VStack(spacing: 6) {
                        Text("Din samling")
                            .font(AntiqueTheme.title(31))
                            .foregroundStyle(AntiqueTheme.forest)
                        Text("Ett personligt katalog över dina upptäckter.")
                            .font(.system(size: 14, design: .serif))
                            .foregroundStyle(AntiqueTheme.mutedInk)
                            .multilineTextAlignment(.center)
                    }

                    BrassDivider()
                        .padding(.horizontal, 35)

                    VStack(spacing: 8) {
                        Text("Här börjar din samling")
                            .font(.system(size: 19, design: .serif))
                            .foregroundStyle(AntiqueTheme.walnut)
                        Text("När du undersöker och sparar ett föremål kommer dess bilder, anteckningar, källor och värderingshistorik att samlas här.")
                            .font(.system(size: 14, design: .serif))
                            .foregroundStyle(AntiqueTheme.mutedInk)
                            .multilineTextAlignment(.center)
                            .lineSpacing(4)
                    }
                    .padding(.horizontal, 28)

                    Text("INGA FÖREMÅL SPARADE ÄNNU")
                        .font(.system(size: 9, weight: .medium, design: .serif))
                        .tracking(1.8)
                        .foregroundStyle(AntiqueTheme.brass)
                        .padding(.top, 8)
                }
                .padding(26)
                .frame(maxWidth: .infinity)
            }
            .toolbar(.hidden, for: .navigationBar)
        }
    }
}
