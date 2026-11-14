import SwiftUI

struct CollectionView: View {
    @EnvironmentObject private var collection: CollectionStore

    var body: some View {
        NavigationStack {
            ZStack {
                PaperBackground()
                if collection.items.isEmpty {
                    emptyState
                } else {
                    ScrollView(showsIndicators: false) {
                        VStack(alignment: .leading, spacing: 18) {
                            VStack(alignment: .leading, spacing: 5) {
                                Text("Din samling")
                                    .font(AntiqueTheme.title(31))
                                    .foregroundStyle(AntiqueTheme.forest)
                                Text("\(collection.items.count) sparade föremål")
                                    .font(.system(size: 13, design: .serif))
                                    .foregroundStyle(AntiqueTheme.mutedInk)
                            }
                            .padding(.top, 25)

                            ForEach(collection.items) { item in
                                HStack(alignment: .top, spacing: 14) {
                                    Group {
                                        if let savedImage = collection.image(for: item) {
                                            Image(uiImage: savedImage).resizable().scaledToFill()
                                        } else {
                                            ZStack {
                                                AntiqueTheme.parchment
                                                Image(systemName: "photo").foregroundStyle(AntiqueTheme.brass)
                                            }
                                        }
                                    }
                                    .frame(width: 104, height: 112)
                                    .clipped()
                                    .overlay(Rectangle().stroke(AntiqueTheme.brass.opacity(0.5), lineWidth: 1))

                                    VStack(alignment: .leading, spacing: 5) {
                                        Text(item.title)
                                            .font(AntiqueTheme.title(20))
                                            .foregroundStyle(AntiqueTheme.forest)
                                        if !item.maker.isEmpty {
                                            Text(item.maker).font(.system(size: 13, design: .serif)).foregroundStyle(AntiqueTheme.walnut)
                                        }
                                        if !item.purchasePrice.isEmpty {
                                            Text("Inköpspris: \(item.purchasePrice) kr").font(.system(size: 12, design: .serif)).foregroundStyle(AntiqueTheme.mutedInk)
                                        }
                                        if !item.notes.isEmpty {
                                            Text(item.notes).font(.system(size: 12, design: .serif)).foregroundStyle(AntiqueTheme.mutedInk).lineLimit(3)
                                        }
                                        Text(item.createdAt.formatted(date: .abbreviated, time: .omitted))
                                            .font(.system(size: 10, design: .serif))
                                            .foregroundStyle(AntiqueTheme.brass)
                                            .padding(.top, 2)
                                    }
                                    Spacer(minLength: 0)
                                }
                                .padding(12)
                                .background(AntiqueTheme.parchment.opacity(0.65))
                                .overlay(RoundedRectangle(cornerRadius: 5).stroke(AntiqueTheme.brass.opacity(0.4), lineWidth: 1))
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.bottom, 30)
                    }
                }
            }
            .toolbar(.hidden, for: .navigationBar)
        }
    }

    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "books.vertical")
                .font(.system(size: 42, weight: .ultraLight))
                .foregroundStyle(AntiqueTheme.brass)
            Text("Din samling")
                .font(AntiqueTheme.title(31))
                .foregroundStyle(AntiqueTheme.forest)
            Text("Ett personligt katalog över dina upptäckter.")
                .font(.system(size: 14, design: .serif))
                .foregroundStyle(AntiqueTheme.mutedInk)
                .multilineTextAlignment(.center)
            BrassDivider().padding(.horizontal, 35)
            Text("Här börjar din samling")
                .font(.system(size: 19, design: .serif))
                .foregroundStyle(AntiqueTheme.walnut)
            Text("Spara ett föremål från skannern så dyker det upp här med bild, anteckningar och inköpspris.")
                .font(.system(size: 14, design: .serif))
                .foregroundStyle(AntiqueTheme.mutedInk)
                .multilineTextAlignment(.center)
                .lineSpacing(4)
                .padding(.horizontal, 26)
            Text("INGA FÖREMÅL SPARADE ÄNNU")
                .font(.system(size: 9, weight: .medium, design: .serif))
                .tracking(1.8)
                .foregroundStyle(AntiqueTheme.brass)
                .padding(.top, 8)
        }
        .padding(26)
    }
}
