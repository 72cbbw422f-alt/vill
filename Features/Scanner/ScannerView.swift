import SwiftUI
import PhotosUI
import UIKit
import Vision

struct ScannerView: View {
    @EnvironmentObject private var collection: CollectionStore
    @State private var selectedPhoto: PhotosPickerItem?
    @State private var image: UIImage?
    @State private var showingCamera = false
    @State private var showingSaveForm = false
    @State private var isRecognizingText = false
    @State private var recognizedText = ""
    @State private var recognitionError: String?
    @State private var imageClues: [String] = []
    @State private var primaryClue: String?

    var body: some View {
        NavigationStack {
            ZStack {
                PaperBackground()
                ScrollView {
                    VStack(spacing: 22) {
                        Text("KURIOSA  •  KONST  •  ANTIKVITETER")
                            .font(.system(size: 10, weight: .semibold, design: .serif))
                            .tracking(1.8)
                            .foregroundStyle(AntiqueTheme.brass)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.top, 14)

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
                                .overlay {
                                    RoundedRectangle(cornerRadius: 5)
                                        .stroke(AntiqueTheme.brass.opacity(0.65), lineWidth: 1)
                                }
                            if let image {
                                Image(uiImage: image)
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

                        VStack(spacing: 12) {
                            if UIImagePickerController.isSourceTypeAvailable(.camera) {
                                Button {
                                    showingCamera = true
                                } label: {
                                    Label("Ta ett foto", systemImage: "camera")
                                        .font(.system(size: 16, weight: .medium, design: .serif))
                                        .foregroundStyle(AntiqueTheme.parchment)
                                        .frame(maxWidth: .infinity)
                                        .padding(16)
                                        .background(AntiqueTheme.forest)
                                        .clipShape(RoundedRectangle(cornerRadius: 5))
                                }
                            } else {
                                Label("Kamera är inte tillgänglig på den här enheten", systemImage: "camera.slash")
                                    .font(.system(size: 13, design: .serif))
                                    .foregroundStyle(AntiqueTheme.mutedInk)
                                    .frame(maxWidth: .infinity)
                                    .padding(12)
                            }

                            PhotosPicker(selection: $selectedPhoto, matching: .images) {
                                Label("Välj en befintlig bild", systemImage: "photo.on.rectangle")
                                    .font(.system(size: 16, weight: .medium, design: .serif))
                                    .foregroundStyle(AntiqueTheme.forest)
                                    .frame(maxWidth: .infinity)
                                    .padding(15)
                                    .background(AntiqueTheme.parchment)
                                    .overlay {
                                        RoundedRectangle(cornerRadius: 5)
                                            .stroke(AntiqueTheme.brass, lineWidth: 1)
                                    }
                                    .clipShape(RoundedRectangle(cornerRadius: 5))
                            }
                            .onChange(of: selectedPhoto) { _, item in
                                Task {
                                    guard let data = try? await item?.loadTransferable(type: Data.self),
                                          let selectedImage = UIImage(data: data) else { return }
                                    image = selectedImage
                                    recognizedText = ""
                                    imageClues = []
                                    primaryClue = nil
                                    recognitionError = nil
                                }
                            }

                            if image != nil {
                                Button(action: recognizeText) {
                                    HStack(spacing: 9) {
                                        if isRecognizingText {
                                            ProgressView().tint(AntiqueTheme.parchment)
                                        } else {
                                            Image(systemName: "text.viewfinder")
                                        }
                                        Text(isRecognizingText ? "Analyserar bilden …" : "Analysera bild lokalt")
                                    }
                                    .font(.system(size: 16, weight: .medium, design: .serif))
                                    .foregroundStyle(AntiqueTheme.parchment)
                                    .frame(maxWidth: .infinity)
                                    .padding(15)
                                    .background(AntiqueTheme.walnut)
                                    .clipShape(RoundedRectangle(cornerRadius: 5))
                                }
                                .disabled(isRecognizingText)

                                Button {
                                    showingSaveForm = true
                                } label: {
                                    Label("Spara i min samling", systemImage: "bookmark")
                                        .font(.system(size: 16, weight: .medium, design: .serif))
                                        .foregroundStyle(AntiqueTheme.walnut)
                                        .frame(maxWidth: .infinity)
                                        .padding(15)
                                        .background(AntiqueTheme.parchment.opacity(0.7))
                                        .overlay {
                                            RoundedRectangle(cornerRadius: 5)
                                                .stroke(AntiqueTheme.brass, lineWidth: 1)
                                        }
                                }
                            }
                        }

                        if primaryClue != nil || !recognizedText.isEmpty {
                            analysisReport
                        }

                        if !imageClues.isEmpty {
                            VStack(alignment: .leading, spacing: 9) {
                                Text("VISUELLA LEDTRÅDAR")
                                    .font(.system(size: 11, weight: .semibold, design: .serif))
                                    .tracking(1.2)
                                    .foregroundStyle(AntiqueTheme.brass)
                                ForEach(Array(imageClues.enumerated()), id: \.offset) { entry in
                                    Label(entry.element, systemImage: "sparkle.magnifyingglass")
                                        .font(.system(size: 14, design: .serif))
                                        .foregroundStyle(AntiqueTheme.ink)
                                }
                                Text("Detta är breda bildkategorier från en generell modell. De fastställer inte föremålets ålder, äkthet, material eller tillverkare.")
                                    .font(.system(size: 12, design: .serif))
                                    .foregroundStyle(AntiqueTheme.mutedInk)
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(15)
                            .background(AntiqueTheme.parchment.opacity(0.8))
                            .overlay(RoundedRectangle(cornerRadius: 5).stroke(AntiqueTheme.brass.opacity(0.5)))
                        }

                        if !recognizedText.isEmpty {
                            VStack(alignment: .leading, spacing: 9) {
                                Text("TEXT SOM KUNDE LÄSAS")
                                    .font(.system(size: 11, weight: .semibold, design: .serif))
                                    .tracking(1.2)
                                    .foregroundStyle(AntiqueTheme.brass)
                                Text(recognizedText)
                                    .font(.system(size: 15, design: .serif))
                                    .foregroundStyle(AntiqueTheme.ink)
                                    .textSelection(.enabled)
                                Text("Kontrollera alltid avläsningen mot originalbilden. Stämplar och äldre handskrift kan misstolkas.")
                                    .font(.system(size: 12, design: .serif))
                                    .foregroundStyle(AntiqueTheme.mutedInk)
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(15)
                            .background(AntiqueTheme.parchment.opacity(0.8))
                            .overlay(RoundedRectangle(cornerRadius: 5).stroke(AntiqueTheme.brass.opacity(0.5)))
                        } else if imageClues.isEmpty, let recognitionError {
                            Text(recognitionError)
                                .font(.system(size: 13, design: .serif))
                                .foregroundStyle(.red)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }

                        Text("Försök gärna få med stämplar, signaturer och eventuella skador. Textigenkänningen sker på telefonen och är ett hjälpmedel – inte en verifierad identifiering.")
                            .font(.system(size: 13, design: .serif))
                            .foregroundStyle(AntiqueTheme.mutedInk)
                            .multilineTextAlignment(.center)
                            .lineSpacing(3)
                    }
                    .padding(.horizontal, 22)
                    .padding(.top, 8)
                    .padding(.bottom, 28)
                    .safeAreaPadding(.bottom, 82)
                }
            }
            .toolbar(.hidden, for: .navigationBar)
            .onChange(of: image) { _, newImage in
                guard newImage != nil else { return }
                recognizedText = ""
                imageClues = []
                primaryClue = nil
                recognitionError = nil
            }
            .sheet(isPresented: $showingCamera) {
                CameraPicker(image: $image).ignoresSafeArea()
            }
            .sheet(isPresented: $showingSaveForm) {
                if let image {
                    SaveAntiqueSheet(image: image, recognizedText: recognizedText)
                        .environmentObject(collection)
                        .presentationDetents([.medium, .large])
                        .presentationDragIndicator(.visible)
                }
            }
        }
    }

    private var analysisReport: some View {
        VStack(alignment: .leading, spacing: 13) {
            Text("PRELIMINÄR FÖREMÅLSRAPPORT")
                .font(.system(size: 11, weight: .semibold, design: .serif))
                .tracking(1.3)
                .foregroundStyle(AntiqueTheme.brass)

            if let primaryClue {
                Text(primaryClue)
                    .font(AntiqueTheme.title(25))
                    .foregroundStyle(AntiqueTheme.forest)
                Text("Bildmodellen känner igen en generell bildkategori. Det är en ledtråd om motivet – inte en säker identifiering av föremålet.")
                    .font(.system(size: 13, design: .serif))
                    .foregroundStyle(AntiqueTheme.mutedInk)
            }

            reportRow("Material och tillverkare", "Kan inte fastställas säkert från den här generella bildanalysen.")
            reportRow("Ålder och ursprung", "Kräver märkningar, konstruktion, materialdetaljer och jämförelser med dokumenterade föremål.")
            reportRow("Marknadsvärde", "Ingen värdering görs utan verifierbara jämförelseförsäljningar.")

            if !recognizedText.isEmpty {
                VStack(alignment: .leading, spacing: 5) {
                    Text("AVLÄST TEXT")
                        .font(.system(size: 10, weight: .semibold, design: .serif))
                        .tracking(1)
                        .foregroundStyle(AntiqueTheme.brass)
                    Text(recognizedText)
                        .font(.system(size: 14, design: .serif))
                        .foregroundStyle(AntiqueTheme.ink)
                        .textSelection(.enabled)
                }
            }

            VStack(alignment: .leading, spacing: 6) {
                Text("NÄSTA BILDER ATT TA")
                    .font(.system(size: 10, weight: .semibold, design: .serif))
                    .tracking(1)
                    .foregroundStyle(AntiqueTheme.brass)
                ForEach(inspectionSuggestions(for: primaryClue), id: \.self) { suggestion in
                    Label(suggestion, systemImage: "camera")
                        .font(.system(size: 13, design: .serif))
                        .foregroundStyle(AntiqueTheme.ink)
                }
            }
            Text("Analysen görs på telefonen. Slutsatser om äkthet, datering och värde kräver fortsatt undersökning.")
                .font(.system(size: 11, design: .serif))
                .foregroundStyle(AntiqueTheme.mutedInk)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(AntiqueTheme.parchment)
        .overlay(RoundedRectangle(cornerRadius: 5).stroke(AntiqueTheme.brass.opacity(0.65), lineWidth: 1))
    }

    private func reportRow(_ heading: String, _ detail: String) -> some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(heading.uppercased())
                .font(.system(size: 10, weight: .semibold, design: .serif))
                .tracking(0.8)
                .foregroundStyle(AntiqueTheme.walnut)
            Text(detail)
                .font(.system(size: 13, design: .serif))
                .foregroundStyle(AntiqueTheme.ink)
        }
    }

    private func inspectionSuggestions(for clue: String?) -> [String] {
        let category = clue?.lowercased() ?? ""
        if category.contains("vas") || category.contains("keramik") || category.contains("porslin") || category.contains("skål") || category.contains("tallrik") || category.contains("kopp") {
            return ["Fotografera undersidan rakt framifrån", "Ta närbild på stämplar, signaturer och etiketter", "Visa eventuell krackelering, nagg och lagningar"]
        }
        if category.contains("möbel") || category.contains("stol") || category.contains("bord") || category.contains("skåp") {
            return ["Fotografera hela föremålet framifrån och bakifrån", "Visa beslag, fogar och undersida", "Ta närbilder på etiketter, märkningar och skador"]
        }
        if category.contains("målning") || category.contains("bild") || category.contains("tavla") {
            return ["Fotografera signaturen i snett dagsljus", "Visa hela baksidan och eventuell etikett", "Ta närbild på ram, duk eller pannå"]
        }
        if category.contains("klock") || category.contains("ur") {
            return ["Fotografera urtavla och visare", "Visa boettens baksida och eventuella nummer", "Dokumentera verk och märkningar om det kan göras säkert"]
        }
        if category.contains("smycke") || category.contains("ring") || category.contains("brosch") {
            return ["Fotografera alla stämplar med makro", "Visa lås, infattningar och baksida", "Ta bild av föremålet bredvid en linjal"]
        }
        return ["Fotografera föremålet från flera vinklar", "Ta skarpa närbilder av stämplar och signaturer", "Visa undersida, baksida och eventuella skador"]
    }

    private func recognizeText() {
        guard let image, let cgImage = image.cgImage else {
            recognitionError = "Bilden kunde inte läsas. Prova att välja eller ta en ny bild."
            return
        }

        isRecognizingText = true
        recognitionError = nil
        recognizedText = ""
        imageClues = []
        primaryClue = nil

        DispatchQueue.global(qos: .userInitiated).async {
            let request = VNRecognizeTextRequest()
            request.recognitionLevel = .accurate
            request.usesLanguageCorrection = true
            request.recognitionLanguages = ["sv-SE", "en-US"]

            let classification = VNClassifyImageRequest()

            do {
                try VNImageRequestHandler(cgImage: cgImage).perform([request, classification])
                let lines = (request.results ?? []).compactMap { $0.topCandidates(1).first?.string }
                let result = lines.joined(separator: "\n")
                let rankedResults = (classification.results ?? [])
                    .filter { $0.confidence >= 0.12 }
                    .prefix(5)
                let clues = rankedResults.map { Self.localizedClue($0.identifier) }
                let leadingClue = rankedResults.first.map { Self.localizedClue($0.identifier) }

                DispatchQueue.main.async {
                    recognizedText = result
                    imageClues = Array(clues)
                    primaryClue = leadingClue
                    if result.isEmpty && clues.isEmpty {
                        recognitionError = "Ingen tydlig text eller bildkategori hittades. Prova en ny bild med bättre ljus."
                    }
                    isRecognizingText = false
                }
            } catch {
                DispatchQueue.main.async {
                    recognitionError = "Texten kunde inte läsas just nu. Försök igen med en ny bild."
                    isRecognizingText = false
                }
            }
        }
    }

    private static func localizedClue(_ identifier: String) -> String {
        let key = identifier.lowercased()
        let translations: [String: String] = [
            "vase": "Vas", "pot": "Kruk", "bowl": "Skål", "plate": "Tallrik",
            "cup": "Kopp", "mug": "Mugg", "teapot": "Tekanna", "bottle": "Flaska",
            "glass": "Glas", "clock": "Klocka", "watch": "Armbandsur", "lamp": "Lampa",
            "chair": "Stol", "table": "Bord", "cabinet": "Skåp", "painting": "Målning",
            "picture": "Bild", "book": "Bok", "sculpture": "Skulptur", "figurine": "Figurin",
            "jewelry": "Smycke", "ring": "Ring", "brooch": "Brosch", "coin": "Mynt",
            "furniture": "Möbel", "wood": "Träföremål", "metal": "Metallföremål",
            "ceramic": "Keramik", "porcelain": "Porslin"
        ]
        return translations[key] ?? identifier.replacingOccurrences(of: "_", with: " ").capitalized
    }
}

private struct SaveAntiqueSheet: View {
    @EnvironmentObject private var collection: CollectionStore
    @Environment(\.dismiss) private var dismiss
    let image: UIImage
    let recognizedText: String

    @State private var title = ""
    @State private var maker = ""
    @State private var purchasePrice = ""
    @State private var notes = ""
    @State private var errorMessage: String?

    var body: some View {
        NavigationStack {
            ZStack {
                PaperBackground()
                ScrollView {
                    VStack(alignment: .leading, spacing: 15) {
                        Text("Anteckna ditt fynd")
                            .font(AntiqueTheme.title(27))
                            .foregroundStyle(AntiqueTheme.forest)
                        field("Föremålets namn", placeholder: "Exempelvis vas, kanna eller tavla", text: $title)
                        field("Tillverkare eller konstnär", placeholder: "Om du känner till den", text: $maker)
                        field("Inköpspris i kronor", placeholder: "Lämna tomt om okänt", text: $purchasePrice)
                            .keyboardType(.decimalPad)

                        VStack(alignment: .leading, spacing: 6) {
                            Text("Egna anteckningar")
                                .font(.system(size: 13, weight: .medium, design: .serif))
                                .foregroundStyle(AntiqueTheme.walnut)
                            TextField("Skick, mått, stämplar, var du hittade föremålet …", text: $notes, axis: .vertical)
                                .lineLimit(3...5)
                                .padding(12)
                                .background(AntiqueTheme.parchment.opacity(0.7))
                                .overlay(RoundedRectangle(cornerRadius: 5).stroke(AntiqueTheme.brass.opacity(0.5)))
                        }
                        if !recognizedText.isEmpty {
                            Text("Den avlästa texten läggs till automatiskt i anteckningarna när föremålet sparas.")
                                .font(.system(size: 12, design: .serif))
                                .foregroundStyle(AntiqueTheme.mutedInk)
                        }
                        if let errorMessage {
                            Text(errorMessage).font(.system(size: 13, design: .serif)).foregroundStyle(.red)
                        }
                        Button(action: save) {
                            Text("Spara föremålet")
                                .font(.system(size: 16, weight: .medium, design: .serif))
                                .foregroundStyle(AntiqueTheme.parchment)
                                .frame(maxWidth: .infinity)
                                .padding(15)
                                .background(AntiqueTheme.forest)
                                .clipShape(RoundedRectangle(cornerRadius: 5))
                        }
                    }
                    .padding(22)
                }
            }
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Avbryt") { dismiss() }.foregroundStyle(AntiqueTheme.forest)
                }
            }
        }
    }

    private func field(_ title: String, placeholder: String, text: Binding<String>) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.system(size: 13, weight: .medium, design: .serif))
                .foregroundStyle(AntiqueTheme.walnut)
            TextField(placeholder, text: text)
                .padding(12)
                .background(AntiqueTheme.parchment.opacity(0.7))
                .overlay(RoundedRectangle(cornerRadius: 5).stroke(AntiqueTheme.brass.opacity(0.5)))
        }
    }

    private func save() {
        let cleanNotes = notes.trimmingCharacters(in: .whitespacesAndNewlines)
        let combinedNotes: String
        if recognizedText.isEmpty {
            combinedNotes = cleanNotes
        } else {
            let extracted = "Text avläst från bilden (kontrollera mot originalet):\n\(recognizedText)"
            combinedNotes = cleanNotes.isEmpty ? extracted : cleanNotes + "\n\n" + extracted
        }

        do {
            try collection.add(title: title, maker: maker, notes: combinedNotes, purchasePrice: purchasePrice, image: image)
            dismiss()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

private struct CameraPicker: UIViewControllerRepresentable {
    @Binding var image: UIImage?
    @Environment(\.dismiss) private var dismiss

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = .camera
        picker.delegate = context.coordinator
        picker.cameraCaptureMode = .photo
        return picker
    }
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}
    func makeCoordinator() -> Coordinator { Coordinator(parent: self) }

    final class Coordinator: NSObject, UINavigationControllerDelegate, UIImagePickerControllerDelegate {
        private let parent: CameraPicker
        init(parent: CameraPicker) { self.parent = parent }

        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
            if let capturedImage = info[.originalImage] as? UIImage { parent.image = capturedImage }
            parent.dismiss()
        }
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) { parent.dismiss() }
    }
}
