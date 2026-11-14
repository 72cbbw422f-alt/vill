import SwiftUI

struct CollectionView: View {
    @EnvironmentObject private var collection: CollectionStore
    @State private var searchText = ""

    private var filteredItems: [SavedAntique] {
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !query.isEmpty else { return collection.items }
        return collection.items.filter { item in
            [item.title, item.maker, item.estimatedPeriod, item.materials, item.markings, item.provenance, item.notes]
                .contains { $0.localizedCaseInsensitiveContains(query) }
        }
    }

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

                            HStack(spacing: 10) {
                                Image(systemName: "magnifyingglass")
                                    .foregroundStyle(AntiqueTheme.brass)
                                TextField("Sök namn, tillverkare, material, märkning …", text: $searchText)
                                    .font(.system(size: 14, design: .serif))
                                    .autocorrectionDisabled()
                                    .textInputAutocapitalization(.never)
                                if !searchText.isEmpty {
                                    Button {
                                        searchText = ""
                                    } label: {
                                        Image(systemName: "xmark.circle.fill")
                                            .foregroundStyle(AntiqueTheme.mutedInk)
                                    }
                                    .accessibilityLabel("Rensa sökning")
                                }
                            }
                            .padding(12)
                            .background(AntiqueTheme.parchment)
                            .overlay(RoundedRectangle(cornerRadius: 5).stroke(AntiqueTheme.brass.opacity(0.55), lineWidth: 1))

                            if filteredItems.isEmpty {
                                VStack(spacing: 8) {
                                    Image(systemName: "magnifyingglass")
                                        .font(.title2)
                                        .foregroundStyle(AntiqueTheme.brass)
                                    Text("Inga föremål matchar sökningen")
                                        .font(AntiqueTheme.title(19))
                                        .foregroundStyle(AntiqueTheme.forest)
                                    Text("Prova ett annat namn, material eller en märkning.")
                                        .font(.system(size: 12, design: .serif))
                                        .foregroundStyle(AntiqueTheme.mutedInk)
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 32)
                            } else {
                                Text(searchText.isEmpty ? "KATALOGREGISTER" : "\(filteredItems.count) TRÄFFAR")
                                    .font(.system(size: 10, weight: .semibold, design: .serif))
                                    .tracking(1.4)
                                    .foregroundStyle(AntiqueTheme.brass)

                                ForEach(filteredItems) { item in
                                    NavigationLink {
                                        AntiqueDetailView(item: item)
                                    } label: {
                                        itemRow(item)
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.bottom, 30)
                        .safeAreaPadding(.bottom, 82)
                    }
                }
            }
            .toolbar(.hidden, for: .navigationBar)
        }
    }

    private func itemRow(_ item: SavedAntique) -> some View {
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
                    Text(item.maker)
                        .font(.system(size: 13, design: .serif))
                        .foregroundStyle(AntiqueTheme.walnut)
                }
                if !item.purchasePrice.isEmpty {
                    Text("Inköpspris: \(item.purchasePrice) kr")
                        .font(.system(size: 12, design: .serif))
                        .foregroundStyle(AntiqueTheme.mutedInk)
                }
                HStack(spacing: 5) {
                    Image(systemName: "photo")
                    Text("\(item.allImageFileNames.count) bilder")
                    Text("·")
                    Text("\(item.evidence.count) prisreferenser")
                }
                .font(.system(size: 10, design: .serif))
                .foregroundStyle(AntiqueTheme.brass)
                Text(item.createdAt.formatted(date: .abbreviated, time: .omitted))
                    .font(.system(size: 10, design: .serif))
                    .foregroundStyle(AntiqueTheme.mutedInk)
                    .padding(.top, 2)
            }
            Spacer(minLength: 0)
            Image(systemName: "chevron.right")
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(AntiqueTheme.brass)
                .padding(.top, 5)
        }
        .padding(12)
        .background(AntiqueTheme.parchment.opacity(0.65))
        .overlay(RoundedRectangle(cornerRadius: 5).stroke(AntiqueTheme.brass.opacity(0.4), lineWidth: 1))
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
