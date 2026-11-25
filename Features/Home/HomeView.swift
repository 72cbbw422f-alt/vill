import SwiftUI

struct HomeView: View {
    @EnvironmentObject private var collection: CollectionStore
    let onScan: () -> Void

    var body: some View {
        NavigationStack {
            ZStack {
                PaperBackground()

                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 26) {
                        masthead

                        VStack(alignment: .leading, spacing: 7) {
                            Text("Välkommen till")
                                .font(.system(size: 15, design: .serif).italic())
                                .foregroundStyle(AntiqueTheme.mutedInk)
                            Text("Antikspanaren")
                                .font(AntiqueTheme.title(40))
                                .foregroundStyle(AntiqueTheme.forest)
                                .minimumScaleFactor(0.8)
                                .lineLimit(1)
                            Text("Upptäck historien bakom föremålen.")
                                .font(.system(size: 17, design: .serif))
                                .foregroundStyle(AntiqueTheme.mutedInk)
                        }

                        Button(action: onScan) {
                            VStack(alignment: .leading, spacing: 18) {
                                HStack {
                                    Image(systemName: "camera.macro")
                                        .font(.system(size: 25, weight: .light))
                                    Spacer()
                                    Text("BÖRJA HÄR")
                                        .font(.system(size: 9, weight: .semibold, design: .serif))
                                        .tracking(2)
                                        .foregroundStyle(AntiqueTheme.parchment.opacity(0.78))
                                }
                                VStack(alignment: .leading, spacing: 5) {
                                    Text("Undersök ett föremål")
                                        .font(AntiqueTheme.title(23))
                                    Text("Ta ett foto eller välj en bild ur biblioteket.")
                                        .font(.system(size: 13, design: .serif))
                                        .opacity(0.84)
                                }
                                HStack {
                                    Text("Starta undersökningen")
                                        .font(.system(size: 13, weight: .medium, design: .serif))
                                    Spacer()
                                    Image(systemName: "arrow.right")
                                }
                                .padding(.top, 2)
                            }
                            .foregroundStyle(AntiqueTheme.parchment)
                            .padding(21)
                            .background {
                                ZStack(alignment: .topTrailing) {
                                    AntiqueTheme.forest
                                    Image(systemName: "sparkle")
                                        .font(.system(size: 100, weight: .ultraLight))
                                        .foregroundStyle(AntiqueTheme.parchment.opacity(0.045))
                                        .offset(x: 12, y: -18)
                                }
                            }
                            .clipShape(RoundedRectangle(cornerRadius: 6))
                            .overlay {
                                RoundedRectangle(cornerRadius: 6)
                                    .stroke(AntiqueTheme.brass.opacity(0.9), lineWidth: 1)
                                    .padding(5)
                            }
                        }
                        .buttonStyle(.plain)

                        collectionPreview

                        VStack(alignment: .leading, spacing: 14) {
                            sectionHeading("Så går det till", eyebrow: "TRE STEG")
                            BrassDivider()
                            HomeStep(number: "I", title: "Dokumentera", detail: "Fotografera hela föremålet, märkningar och detaljer.")
                            HomeStep(number: "II", title: "Undersök", detail: "Leta efter tillverkare, material, ålder och ursprung.")
                            HomeStep(number: "III", title: "Jämför värdet", detail: "Väg uppskattningar mot verkliga auktionsresultat.")
                        }

                        VStack(alignment: .leading, spacing: 10) {
                            sectionHeading("Vår ledstjärna", eyebrow: "KÄLLKRITIK")
                            HStack(alignment: .top, spacing: 12) {
                                Image(systemName: "book.closed")
                                    .font(.system(size: 20, weight: .light))
                                    .foregroundStyle(AntiqueTheme.brass)
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Kunskap före tvärsäkerhet.")
                                        .font(.system(size: 16, design: .serif).italic())
                                        .foregroundStyle(AntiqueTheme.forest)
                                    Text("Vi ska alltid skilja verifierade uppgifter från AI-förslag, uppskattningar och obekräftade ledtrådar.")
                                        .font(.system(size: 13, design: .serif))
                                        .foregroundStyle(AntiqueTheme.mutedInk)
                                        .fixedSize(horizontal: false, vertical: true)
                                }
                            }
                            .padding(16)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(AntiqueTheme.parchment.opacity(0.72))
                            .overlay(alignment: .leading) {
                                Rectangle().fill(AntiqueTheme.brass).frame(width: 2)
                            }
                        }

                        HStack {
                            Spacer()
                            Text("✦  ANTIKSPANAREN  ✦")
                                .font(.system(size: 9, weight: .medium, design: .serif))
                                .tracking(2)
                                .foregroundStyle(AntiqueTheme.brass)
                            Spacer()
                        }
                        .padding(.top, 4)
                        .padding(.bottom, 24)
                    }
                    .padding(.horizontal, 22)
                }
                .safeAreaPadding(.bottom, 82)
            }
            .toolbar(.hidden, for: .navigationBar)
        }
    }

    private var collectionPreview: some View {
        VStack(alignment: .leading, spacing: 13) {
            HStack(alignment: .firstTextBaseline) {
                sectionHeading("Ur din samling", eyebrow: "DINA FÖREMÅL")
                Spacer()
                Text("\(collection.items.count) SPARADE")
                    .font(.system(size: 9, weight: .semibold, design: .serif))
                    .tracking(1)
                    .foregroundStyle(AntiqueTheme.brass)
            }

            if collection.items.isEmpty {
                HStack(alignment: .top, spacing: 12) {
                    Image(systemName: "books.vertical")
                        .font(.system(size: 21, weight: .light))
                        .foregroundStyle(AntiqueTheme.brass)
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Din samling börjar här.")
                            .font(.system(size: 16, design: .serif))
                            .foregroundStyle(AntiqueTheme.forest)
                        Text("Spara det första föremålet så visas det här, tillsammans med dina senaste dokumentationer.")
                            .font(.system(size: 13, design: .serif))
                            .foregroundStyle(AntiqueTheme.mutedInk)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
                .padding(16)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(AntiqueTheme.parchment.opacity(0.72))
                .overlay(alignment: .leading) {
                    Rectangle().fill(AntiqueTheme.brass).frame(width: 2)
                }
            } else {
                ForEach(Array(collection.items.prefix(2))) { item in
                    NavigationLink {
                        AntiqueDetailView(item: item)
                    } label: {
                        HStack(spacing: 13) {
                            Group {
                                if let savedImage = collection.image(for: item) {
                                    Image(uiImage: savedImage)
                                        .resizable()
                                        .scaledToFill()
                                } else {
                                    ZStack {
                                        AntiqueTheme.parchment
                                        Image(systemName: "photo")
                                            .foregroundStyle(AntiqueTheme.brass)
                                    }
                                }
                            }
                            .frame(width: 72, height: 76)
                            .clipped()
                            .overlay(Rectangle().stroke(AntiqueTheme.brass.opacity(0.5), lineWidth: 1))

                            VStack(alignment: .leading, spacing: 5) {
                                Text(item.title.isEmpty ? "Namnlöst föremål" : item.title)
                                    .font(AntiqueTheme.title(19))
                                    .foregroundStyle(AntiqueTheme.forest)
                                    .lineLimit(2)
                                    .multilineTextAlignment(.leading)
                                if !item.maker.isEmpty {
                                    Text(item.maker)
                                        .font(.system(size: 12, design: .serif))
                                        .foregroundStyle(AntiqueTheme.walnut)
                                        .lineLimit(1)
                                }
                                Text("\(item.allImageFileNames.count) bilder · \(item.evidence.count) prisreferenser")
                                    .font(.system(size: 10, design: .serif))
                                    .foregroundStyle(AntiqueTheme.mutedInk)
                            }
                            Spacer(minLength: 0)
                            Image(systemName: "chevron.right")
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundStyle(AntiqueTheme.brass)
                        }
                        .padding(10)
                        .background(AntiqueTheme.parchment.opacity(0.72))
                        .overlay(RoundedRectangle(cornerRadius: 5).stroke(AntiqueTheme.brass.opacity(0.35), lineWidth: 1))
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private var masthead: some View {
        HStack(spacing: 10) {
            Image(systemName: "rosette")
                .font(.system(size: 19, weight: .light))
                .foregroundStyle(AntiqueTheme.brass)
            VStack(alignment: .leading, spacing: 2) {
                Text("KURIOSA  •  KONST  •  ANTIKVITETER")
                    .font(.system(size: 9, weight: .semibold, design: .serif))
                    .tracking(1.5)
                    .foregroundStyle(AntiqueTheme.brass)
                Text("EN GUIDE FÖR NYFIKNA SAMLARE")
                    .font(.system(size: 8, design: .serif))
                    .tracking(1.2)
                    .foregroundStyle(AntiqueTheme.mutedInk)
            }
            Spacer()
            Image(systemName: "sparkle")
                .font(.system(size: 14))
                .foregroundStyle(AntiqueTheme.brass.opacity(0.8))
        }
        .padding(.top, 14)
        .padding(.bottom, 12)
        .overlay(alignment: .bottom) { BrassDivider() }
    }

    private func sectionHeading(_ title: String, eyebrow: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(eyebrow)
                .font(.system(size: 9, weight: .semibold, design: .serif))
                .tracking(2)
                .foregroundStyle(AntiqueTheme.brass)
            Text(title)
                .font(AntiqueTheme.title(25))
                .foregroundStyle(AntiqueTheme.forest)
        }
    }
}

private struct HomeStep: View {
    let number: String
    let title: String
    let detail: String

    var body: some View {
        HStack(alignment: .top, spacing: 14) {
            Text(number)
                .font(.system(size: 17, design: .serif).italic())
                .foregroundStyle(AntiqueTheme.brass)
                .frame(width: 25)
            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.system(size: 17, design: .serif))
                    .foregroundStyle(AntiqueTheme.ink)
                Text(detail)
                    .font(.system(size: 13, design: .serif))
                    .foregroundStyle(AntiqueTheme.mutedInk)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }
}
