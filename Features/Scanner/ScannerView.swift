import SwiftUI
import PhotosUI
import UIKit

struct ScannerView: View {
    @State private var selectedPhoto: PhotosPickerItem?
    @State private var image: Image?

    var body: some View {
        NavigationStack {
            ZStack {
                PaperBackground()
                ScrollView {
                    VStack(spacing: 20) {
                        VStack(spacing: 8) {
                            Text("Föremålets berättelse")
                                .font(AntiqueTheme.title(30))
                                .foregroundStyle(AntiqueTheme.forest)
                            Text("Börja med en tydlig bild i dagsljus.")
                                .font(.system(size: 15, design: .serif))
                                .foregroundStyle(AntiqueTheme.mutedInk)
                        }
                        .padding(.top, 24)

                        ZStack {
                            RoundedRectangle(cornerRadius: 5)
                                .fill(AntiqueTheme.parchment)
                                .overlay(RoundedRectangle(cornerRadius: 5).stroke(AntiqueTheme.brass.opacity(0.65), lineWidth: 1))
                            if let image {
                                image
                                    .resizable()
                                    .scaledToFit()
                                    .padding(12)
                            } else {
                                VStack(spacing: 12) {
                                    Image(systemName: "camera.macro")
                                        .font(.system(size: 48, weight: .ultraLight))
                                    Text("Din bild visas här")
                                        .font(.system(size: 16, design: .serif))
                                }
                                .foregroundStyle(AntiqueTheme.walnut.opacity(0.75))
                            }
                        }
                        .frame(height: 300)

                        PhotosPicker(selection: $selectedPhoto, matching: .images) {
                            Label("Välj foto från biblioteket", systemImage: "photo")
                                .font(.system(size: 16, design: .serif))
                                .foregroundStyle(AntiqueTheme.parchment)
                                .frame(maxWidth: .infinity)
                                .padding(16)
                                .background(AntiqueTheme.forest)
                                .clipShape(RoundedRectangle(cornerRadius: 5))
                        }
                        .onChange(of: selectedPhoto) { _, item in
                            Task {
                                guard let data = try? await item?.loadTransferable(type: Data.self),
                                      let uiImage = UIImage(data: data) else { return }
                                image = Image(uiImage: uiImage)
                            }
                        }

                        Text("Identifiering och värdering kopplas in i nästa utvecklingssteg. Ingen analys eller värdering görs ännu.")
                            .font(.system(size: 13, design: .serif))
                            .foregroundStyle(AntiqueTheme.mutedInk)
                            .multilineTextAlignment(.center)
                    }
                    .padding(22)
                }
            }
            .navigationBarHidden(true)
        }
    }
}