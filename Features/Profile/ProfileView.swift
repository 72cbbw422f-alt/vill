import SwiftUI

struct ProfileView: View {
    var body: some View {
        NavigationStack {
            ZStack {
                PaperBackground()

                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 22) {
                        VStack(spacing: 10) {
                            Image(systemName: "seal")
                                .font(.system(size: 43, weight: .ultraLight))
                                .foregroundStyle(AntiqueTheme.brass)
                            Text("Om Antikspanaren")
                                .font(AntiqueTheme.title(30))
                                .foregroundStyle(AntiqueTheme.forest)
                            Text("Ett verktyg för nyfikna samlare och fyndjägare.")
                                .font(.system(size: 15, design: .serif))
                                .foregroundStyle(AntiqueTheme.mutedInk)
                                .multilineTextAlignment(.center)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.top, 30)

                        BrassDivider()

                        infoSection("Vårt löfte", body: "Antikspanaren ska hjälpa dig att ställa bättre frågor om föremål – inte låtsas veta sådant som inte går att belägga.")

                        infoSection("Så redovisar vi värde", body: "Begärda priser, auktionshusens värderingar och klubbade slutpriser är olika saker. De ska hållas isär och presenteras med datum och källa.")

                        infoSection("Osäkerhet ska synas", body: "En möjlig identifiering är en ledtråd, inte ett bevis. Skick, proveniens, äkthet och jämförbarhet påverkar alltid bedömningen.")

                        VStack(alignment: .leading, spacing: 7) {
                            Text("ANTIKSPANAREN")
                                .font(.system(size: 10, weight: .semibold, design: .serif))
                                .tracking(2)
                                .foregroundStyle(AntiqueTheme.brass)
                            Text("Ett anrikt auktionshus möter modern teknik.")
                                .font(.system(size: 16, design: .serif).italic())
                                .foregroundStyle(AntiqueTheme.forest)
                        }
                        .padding(18)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(AntiqueTheme.parchment)
                        .overlay {
                            RoundedRectangle(cornerRadius: 4)
                                .stroke(AntiqueTheme.brass.opacity(0.6), lineWidth: 1)
                        }
                        .padding(.bottom, 25)
                    }
                    .padding(.horizontal, 22)
                }
                .safeAreaPadding(.bottom, 82)
            }
            .toolbar(.hidden, for: .navigationBar)
        }
    }

    private func infoSection(_ title: String, body: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(AntiqueTheme.title(21))
                .foregroundStyle(AntiqueTheme.forest)
            Text(body)
                .font(.system(size: 14, design: .serif))
                .foregroundStyle(AntiqueTheme.mutedInk)
                .lineSpacing(4)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}
