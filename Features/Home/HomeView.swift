import SwiftUI

struct HomeView: View {
    let onScan: () -> Void

    var body: some View {
        NavigationStack {
            ZStack {
                PaperBackground()
                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 25) {
                        HStack {
                            Text("✦  ANTIK • KONST • KURIOSA")
                                .font(.system(size: 10, weight: .semibold, design: .serif))
                                .tracking(2.5)
                                .foregroundStyle(AntiqueTheme.brass)
                            Spacer()
                            Image(systemName: "sparkle")
                                .foregroundStyle(AntiqueTheme.brass)
                        }
                        .padding(.top, 12)

                        VStack(alignment: .leading, spacing: 8) {
                            Text("Antikspanaren")
                                .font(AntiqueTheme.title(39))
                                .foregroundStyle(AntiqueTheme.forest)
                            Text("Upptäck historien bakom föremålen.")
                                .font(.system(size: 17, design: .serif))
                                .foregroundStyle(AntiqueTheme.mutedInk)
                        }

                        Button(action: onScan) {
                            HStack(spacing: 16) {
                                Image(systemName: "camera.viewfinder")
                                    .font(.system(size: 27, weight: .light))
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Undersök ett föremål")
                                        .font(.system(size: 19, design: .serif))
                                    Text("Fotografera och börja upptäcka")
                                        .font(.system(size: 12, design: .serif))
                                        .opacity(0.82)
                                }
                                Spacer()
                                Image(systemName: "arrow.right")
                            }
                            .foregroundStyle(AntiqueTheme.parchment)
                            .padding(20)
                            .background(AntiqueTheme.forest)
                            .clipShape(RoundedRectangle(cornerRadius: 5))
                            .overlay(RoundedRectangle(cornerRadius: 5).stroke(AntiqueTheme.brass, lineWidth: 1).padding(5))
                        }
                        .buttonStyle(.plain)

                        VStack(alignment: .leading, spacing: 13) {
                            Text("En varsam väg till kunskap")
                                .font(AntiqueTheme.title(25))
                                .foregroundStyle(AntiqueTheme.forest)
                            BrassDivider()
                            HomeStep(number: "I", title: "Fotografera", detail: "Fånga föremålet, märkningen eller signaturen.")
                            HomeStep(number: "II", title: "Identifiera", detail: "Undersök tillverkare, material, ålder och ursprung.")
                            HomeStep(number: "III", title: "Värdera", detail: "Jämför med dokumenterade försäljningar.")
                        }

                        VStack(alignment: .leading, spacing: 7) {
                            Text("Kunskap med varsamhet.")
                                .font(.system(size: 15, design: .serif).italic())
                            Text("Vi skiljer alltid mellan belagda uppgifter och uppskattningar.")
                                .font(.system(size: 12, design: .serif))
                        }
                        .foregroundStyle(AntiqueTheme.mutedInk)
                        .padding(.top, 5)
                        .padding(.bottom, 25)
                    }
                    .padding(.horizontal, 22)
                }
            }
            .toolbar(.hidden, for: .navigationBar)
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
            }
        }
    }
}