import SwiftUI

struct ProfileView: View {
    var body: some View {
        NavigationStack {
            ZStack {
                PaperBackground()
                VStack(spacing: 12) {
                    Image(systemName: "seal")
                        .font(.system(size: 38, weight: .ultraLight))
                        .foregroundStyle(AntiqueTheme.brass)
                    Text("Om Antikspanaren")
                        .font(AntiqueTheme.title(29))
                        .foregroundStyle(AntiqueTheme.forest)
                    Text("Ett verktyg för nyfikna samlare och fyndjägare. Vårt mål är att göra antik kunskap mer tillgänglig – utan att tumma på källkritiken.")
                        .font(.system(size: 14, design: .serif))
                        .foregroundStyle(AntiqueTheme.mutedInk)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 30)
                }
            }
            .navigationBarHidden(true)
        }
    }
}