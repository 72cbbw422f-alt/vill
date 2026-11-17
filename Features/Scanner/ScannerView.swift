import SwiftUI
import PhotosUI
import UIKit
import Vision
import ImageIO

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
    @State private var imageClueDetails: [String] = []
    @State private var primaryClue: String?
    @State private var rawMarkingText = ""
    @State private var museumSearchText = ""
    @State private var sourceSearchText = ""
    @State private var museumResults: [MetMuseumObject] = []
    @State private var isSearchingMuseums = false
    @State private var museumSearchError: String?
    @State private var collectionMatches: [CollectionImageMatch] = []
    @State private var isComparingCollection = false

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
                                    imageClueDetails = []
                                    primaryClue = nil
                                    rawMarkingText = ""
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

                        if image != nil {
                            museumSearchPanel
                            collectionComparisonPanel
                        }

                        if !imageClues.isEmpty {
                            VStack(alignment: .leading, spacing: 9) {
                                Text("BILDMODELLENS OBSERVATIONER")
                                    .font(.system(size: 11, weight: .semibold, design: .serif))
                                    .tracking(1.2)
                                    .foregroundStyle(AntiqueTheme.brass)
                                ForEach(Array(imageClueDetails.enumerated()), id: \.offset) { entry in
                                    Label(entry.element, systemImage: "sparkle.magnifyingglass")
                                        .font(.system(size: 14, design: .serif))
                                        .foregroundStyle(AntiqueTheme.ink)
                                }
                                Text("Detta är motiv- och objektledtrådar från en generell bildmodell. De är inte en identifiering och fastställer inte material, ålder, äkthet eller tillverkare.")
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
                        } else if imageClues.isEmpty, collectionMatches.isEmpty, let recognitionError {
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
                    .padding(.top, 16)
                    .padding(.bottom, 36)
                }
                // Keep the ScrollView viewport full-height. A bottom safeAreaInset
                // here reduced the visible viewport and produced a hard horizontal
                // clipping edge above the tab bar. Add scroll-content margin instead.
                .contentMargins(.bottom, 112, for: .scrollContent)
            }
            .toolbar(.hidden, for: .navigationBar)
            .onChange(of: image) { _, newImage in
                guard newImage != nil else { return }
                recognizedText = ""
                imageClues = []
                imageClueDetails = []
                primaryClue = nil
                rawMarkingText = ""
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


    private var collectionComparisonPanel: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("JÄMFÖR MED DIN SAMLING")
                .font(.system(size: 11, weight: .semibold, design: .serif))
                .tracking(1.2)
                .foregroundStyle(AntiqueTheme.brass)
            Text("Jämför bildens visuella drag med sparade bilder. Resultatet är en sorterad bildlikhet, inte en identifiering. Olika föremål kan hamna nära varandra.")
                .font(.system(size: 13, design: .serif))
                .foregroundStyle(AntiqueTheme.mutedInk)
            Button(action: compareWithCollection) {
                HStack(spacing: 8) {
                    if isComparingCollection {
                        ProgressView().tint(AntiqueTheme.parchment)
                    } else {
                        Image(systemName: "square.stack.3d.up")
                    }
                    Text(isComparingCollection ? "Jämför med samlingen …" : "Jämför med mina sparade föremål")
                }
                .font(.system(size: 15, weight: .medium, design: .serif))
                .foregroundStyle(AntiqueTheme.parchment)
                .frame(maxWidth: .infinity)
                .padding(13)
                .background(AntiqueTheme.forest)
                .clipShape(RoundedRectangle(cornerRadius: 5))
            }
            .disabled(isComparingCollection || collection.items.isEmpty)
            if collection.items.isEmpty {
                Text("Spara några föremål i samlingen för att kunna jämföra dem här.")
                    .font(.system(size: 12, design: .serif))
                    .foregroundStyle(AntiqueTheme.mutedInk)
            }
            ForEach(collectionMatches) { match in
                VStack(alignment: .leading, spacing: 3) {
                    Text(match.title)
                        .font(.system(size: 15, weight: .medium, design: .serif))
                        .foregroundStyle(AntiqueTheme.forest)
                    Text("Närmaste visuella bildträff i din samling – kontrollera själv om föremålen verkligen liknar varandra.")
                        .font(.system(size: 11, design: .serif))
                        .foregroundStyle(AntiqueTheme.mutedInk)
                }
            }
            if !collectionMatches.isEmpty {
                Text("Matchningen bygger på bilddrag och är endast en lokal jämförelse. Den fastställer inte identitet, ålder eller proveniens.")
                    .font(.system(size: 11, design: .serif))
                    .foregroundStyle(AntiqueTheme.mutedInk)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(15)
        .background(AntiqueTheme.parchment.opacity(0.8))
        .overlay(RoundedRectangle(cornerRadius: 5).stroke(AntiqueTheme.brass.opacity(0.5)))
    }

    private func compareWithCollection() {
        guard let image, let queryCGImage = image.cgImage else { return }
        let candidates = collection.items.compactMap { item -> (String, UIImage)? in
            guard let candidateImage = collection.image(for: item) else { return nil }
            return (item.title, candidateImage)
        }
        guard !candidates.isEmpty else {
            collectionMatches = []
            return
        }
        isComparingCollection = true
        collectionMatches = []
        DispatchQueue.global(qos: .userInitiated).async {
            var matches: [(title: String, distance: Float)] = []
            let queryRequest = VNGenerateImageFeaturePrintRequest()
            queryRequest.imageCropAndScaleOption = .centerCrop
            do {
                try VNImageRequestHandler(cgImage: queryCGImage, orientation: CGImagePropertyOrientation(image.imageOrientation)).perform([queryRequest])
                guard let queryPrint = queryRequest.results?.first else { throw NSError(domain: "Antikspanaren", code: 1) }
                for (title, candidate) in candidates {
                    guard let cgImage = candidate.cgImage else { continue }
                    let request = VNGenerateImageFeaturePrintRequest()
                    request.imageCropAndScaleOption = .centerCrop
                    try VNImageRequestHandler(cgImage: cgImage, orientation: CGImagePropertyOrientation(candidate.imageOrientation)).perform([request])
                    guard let candidatePrint = request.results?.first else { continue }
                    var distance: Float = 0
                    try queryPrint.computeDistance(&distance, to: candidatePrint)
                    matches.append((title, distance))
                }
                let sorted = matches.sorted { $0.distance < $1.distance }.prefix(3)
                DispatchQueue.main.async {
                    collectionMatches = sorted.map { CollectionImageMatch(title: $0.title, distance: $0.distance) }
                    isComparingCollection = false
                }
            } catch {
                DispatchQueue.main.async {
                    collectionMatches = []
                    isComparingCollection = false
                    recognitionError = "Bildjämförelsen kunde inte genomföras. Försök igen."
                }
            }
        }
    }

    private var sourceResearchPanel: some View {
        let hasSearchTerm = !sourceSearchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        let hasAnalysisText = !recognizedText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            || !rawMarkingText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            || primaryClue != nil

        return VStack(alignment: .leading, spacing: 12) {
            Text("AUKTIONSHUS & MARKNADSRESEARCH")
                .font(.system(size: 11, weight: .semibold, design: .serif))
                .tracking(1.2)
                .foregroundStyle(AntiqueTheme.brass)
            Text("Sök efter liknande föremål hos de källor Villemo använder. Sökningarna öppnas i webbläsaren och hämtar inte automatiskt auktionsresultat.")
                .font(.system(size: 13, design: .serif))
                .foregroundStyle(AntiqueTheme.mutedInk)
            TextField("Exempelvis Gustavsberg Argenta vas", text: $sourceSearchText)
                .textInputAutocapitalization(.words)
                .autocorrectionDisabled()
                .padding(12)
                .background(AntiqueTheme.paper)
                .overlay(RoundedRectangle(cornerRadius: 5).stroke(AntiqueTheme.brass.opacity(0.5)))
            if hasAnalysisText {
                Button {
                    prepareAuctionSearch()
                } label: {
                    Label("Använd avläst text i sökningen", systemImage: "text.magnifyingglass")
                        .font(.system(size: 13, weight: .medium, design: .serif))
                        .foregroundStyle(AntiqueTheme.forest)
                }
            }
            if hasSearchTerm {
                VStack(spacing: 8) {
                    sourceSearchLink("Auctionet", domain: "auctionet.com", icon: "hammer")
                    sourceSearchLink("Catawiki", domain: "catawiki.com", icon: "globe.europe.africa")
                    sourceSearchLink("Barnebys", domain: "barnebys.com", icon: "magnifyingglass")
                    sourceSearchLink("Bukowskis", domain: "bukowskis.com", icon: "building.columns")
                    sourceSearchLink("Stockholms Auktionsverk", domain: "stockholmsauktionsverk.com", icon: "building.2")
                    if let imageSearchURL = sourceSearchURL(domain: nil, images: true) {
                        Link(destination: imageSearchURL) {
                            Label("Bildsök – Google Bilder", systemImage: "photo.on.rectangle.angled")
                                .font(.system(size: 14, weight: .medium, design: .serif))
                                .foregroundStyle(AntiqueTheme.forest)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(12)
                                .background(AntiqueTheme.paper)
                                .overlay(RoundedRectangle(cornerRadius: 5).stroke(AntiqueTheme.brass.opacity(0.55)))
                        }
                    }
                }
            } else {
                Text("Skriv ett sökord eller använd text som lästs av från bilden för att aktivera sökningarna.")
                    .font(.system(size: 12, design: .serif))
                    .foregroundStyle(AntiqueTheme.mutedInk)
            }
            Text("Tips: sök på tillverkare, modell, signatur eller material. Jämför avslutade försäljningar separat från utropspriser och aktiva annonser. Samma objekt kan förekomma på flera plattformar.")
                .font(.system(size: 11, design: .serif))
                .foregroundStyle(AntiqueTheme.mutedInk)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(AntiqueTheme.parchment)
        .overlay(RoundedRectangle(cornerRadius: 5).stroke(AntiqueTheme.brass.opacity(0.65), lineWidth: 1))
    }

    private func prepareAuctionSearch() {
        let source = rawMarkingText.isEmpty ? recognizedText : rawMarkingText
        let cleanedLines = source
            .components(separatedBy: .newlines)
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
        let extracted = cleanedLines.prefix(3).joined(separator: " ")
        if !extracted.isEmpty {
            sourceSearchText = String(extracted.prefix(100))
        } else if let primaryClue {
            sourceSearchText = primaryClue
        }
    }

    @ViewBuilder
    private func sourceSearchLink(_ title: String, domain: String, icon: String) -> some View {
        if let url = sourceSearchURL(domain: domain) {
            Link(destination: url) {
                HStack {
                    Label(title, systemImage: icon)
                    Spacer()
                    Image(systemName: "arrow.up.right")
                        .font(.system(size: 11, weight: .semibold))
                }
                .font(.system(size: 14, weight: .medium, design: .serif))
                .foregroundStyle(AntiqueTheme.forest)
                .padding(12)
                .background(AntiqueTheme.paper)
                .overlay(RoundedRectangle(cornerRadius: 5).stroke(AntiqueTheme.brass.opacity(0.55)))
            }
        }
    }

    private func sourceSearchURL(domain: String?, images: Bool = false) -> URL? {
        let term = sourceSearchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !term.isEmpty else { return nil }
        var query = term
        if let domain { query += " site:" + domain }
        var components = URLComponents(string: "https://www.google.com/search")
        var items = [URLQueryItem(name: "q", value: query)]
        if images { items.append(URLQueryItem(name: "tbm", value: "isch")) }
        components?.queryItems = items
        return components?.url
    }

    private var museumSearchPanel: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("JÄMFÖR MED DOKUMENTERADE FÖREMÅL")
                .font(.system(size: 11, weight: .semibold, design: .serif))
                .tracking(1.2)
                .foregroundStyle(AntiqueTheme.brass)
            Text("Sök i Metropolitan Museum of Arts öppna samling. Träffar är jämförelsematerial – inte bevis för att ditt föremål är samma objekt.")
                .font(.system(size: 13, design: .serif))
                .foregroundStyle(AntiqueTheme.mutedInk)
            TextField("Exempel: Rörstrand, porslinsvas …", text: $museumSearchText)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .padding(12)
                .background(AntiqueTheme.paper)
                .overlay(RoundedRectangle(cornerRadius: 5).stroke(AntiqueTheme.brass.opacity(0.5)))
            Button {
                Task { await searchMetCollection() }
            } label: {
                HStack {
                    if isSearchingMuseums { ProgressView().tint(AntiqueTheme.parchment) }
                    Label(isSearchingMuseums ? "Söker i museisamlingen …" : "Sök i museisamlingen", systemImage: "building.columns")
                }
                .font(.system(size: 15, weight: .medium, design: .serif))
                .foregroundStyle(AntiqueTheme.parchment)
                .frame(maxWidth: .infinity)
                .padding(14)
                .background(AntiqueTheme.forest)
                .clipShape(RoundedRectangle(cornerRadius: 5))
            }
            .disabled(isSearchingMuseums || museumSearchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)

            if let museumSearchError {
                Text(museumSearchError)
                    .font(.system(size: 12, design: .serif))
                    .foregroundStyle(.red)
            }

            if !museumResults.isEmpty {
                Text("TRÄFFAR I MUSEETS KATALOG")
                    .font(.system(size: 10, weight: .semibold, design: .serif))
                    .tracking(1)
                    .foregroundStyle(AntiqueTheme.brass)
                ForEach(museumResults) { item in
                    VStack(alignment: .leading, spacing: 5) {
                        Text(item.title.isEmpty ? "Utan titel" : item.title)
                            .font(.system(size: 16, weight: .medium, design: .serif))
                            .foregroundStyle(AntiqueTheme.forest)
                        if !item.artistDisplayName.isEmpty {
                            Text(item.artistDisplayName)
                                .font(.system(size: 13, design: .serif))
                                .foregroundStyle(AntiqueTheme.ink)
                        }
                        if !item.objectDate.isEmpty || !item.medium.isEmpty {
                            Text([item.objectDate, item.medium].filter { !$0.isEmpty }.joined(separator: " · "))
                                .font(.system(size: 12, design: .serif))
                                .foregroundStyle(AntiqueTheme.mutedInk)
                        }
                        if !item.department.isEmpty {
                            Text(item.department.uppercased())
                                .font(.system(size: 9, weight: .semibold, design: .serif))
                                .tracking(0.8)
                                .foregroundStyle(AntiqueTheme.walnut)
                        }
                        if let url = URL(string: item.objectURL), !item.objectURL.isEmpty {
                            Link("Visa museets katalogpost", destination: url)
                                .font(.system(size: 12, weight: .medium, design: .serif))
                                .foregroundStyle(AntiqueTheme.forest)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.vertical, 10)
                    if item.id != museumResults.last?.id {
                        BrassDivider()
                    }
                }
                Text("Museiposter beskriver föremål i samlingen. De är inte auktionsresultat och kan inte användas ensamma för marknadsvärdering.")
                    .font(.system(size: 11, design: .serif))
                    .foregroundStyle(AntiqueTheme.mutedInk)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(AntiqueTheme.parchment)
        .overlay(RoundedRectangle(cornerRadius: 5).stroke(AntiqueTheme.brass.opacity(0.65), lineWidth: 1))
    }

    @MainActor
    private func searchMetCollection() async {
        let term = museumSearchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !term.isEmpty else { return }
        isSearchingMuseums = true
        museumSearchError = nil
        museumResults = []
        defer { isSearchingMuseums = false }

        do {
            var components = URLComponents(string: "https://collectionapi.metmuseum.org/public/collection/v1.1/search")!
            components.queryItems = [URLQueryItem(name: "q", value: term), URLQueryItem(name: "hasImages", value: "true")]
            guard let searchURL = components.url else { throw MetSearchError.invalidURL }
            let (searchData, _) = try await URLSession.shared.data(from: searchURL)
            let search = try JSONDecoder().decode(MetSearchResponse.self, from: searchData)
            let ids = Array((search.objectIDs ?? []).prefix(5))
            guard !ids.isEmpty else {
                museumSearchError = "Inga träffar hittades. Prova ett annat namn, material eller en engelsk sökterm."
                return
            }

            var found: [MetMuseumObject] = []
            for id in ids {
                guard let url = URL(string: "https://collectionapi.metmuseum.org/public/collection/v1/objects/\(id)") else { continue }
                do {
                    let (data, _) = try await URLSession.shared.data(from: url)
                    let object = try JSONDecoder().decode(MetMuseumObject.self, from: data)
                    if object.isPublicDomain { found.append(object) }
                } catch {
                    continue
                }
            }
            museumResults = found
            if found.isEmpty {
                museumSearchError = "Museet hittade poster, men inga bildposter kunde hämtas just nu."
            }
        } catch {
            museumSearchError = "Kunde inte nå museisamlingen. Kontrollera internetanslutningen och försök igen."
        }
    }

    private var analysisReport: some View {
        VStack(alignment: .leading, spacing: 13) {
            Text("PRELIMINÄR FÖREMÅLSRAPPORT")
                .font(.system(size: 11, weight: .semibold, design: .serif))
                .tracking(1.3)
                .foregroundStyle(AntiqueTheme.brass)

            if let primaryClue {
                Text("Bildmodellens ledtråd")
                    .font(.system(size: 10, weight: .semibold, design: .serif))
                    .tracking(0.8)
                    .foregroundStyle(AntiqueTheme.walnut)
                Text(primaryClue)
                    .font(AntiqueTheme.title(25))
                    .foregroundStyle(AntiqueTheme.forest)
                Text("Detta är modellens bästa bildledtråd – inte en identifiering. Bildmodellen kan förväxla föremål med miljö och motiv. Använd därför inte kategorin som föremålsnamn förrän den stämmer med bilden.")
                    .font(.system(size: 13, design: .serif))
                    .foregroundStyle(AntiqueTheme.mutedInk)
                reportRow("Vad som behöver kontrolleras", inspectionSummary(for: primaryClue))
            }

            reportRow("Material och tillverkare", "Inte fastställda. Material kräver kontroll av yta, vikt, ljud, genomlysning eller annan lämplig undersökning. Tillverkare kräver jämförbar märkning eller dokumentation.")
            reportRow("Ålder och ursprung", "Kräver märkningar, konstruktion, materialdetaljer och jämförelser med dokumenterade föremål.")
            reportRow("Marknadsvärde", "Ingen värdering görs utan verifierbara jämförelseförsäljningar.")

            if !rawMarkingText.isEmpty && rawMarkingText != recognizedText {
                VStack(alignment: .leading, spacing: 5) {
                    Text("RÅ AVLÄSNING – MÄRKNINGAR")
                        .font(.system(size: 10, weight: .semibold, design: .serif))
                        .tracking(1)
                        .foregroundStyle(AntiqueTheme.brass)
                    Text(rawMarkingText)
                        .font(.system(size: 14, design: .monospaced))
                        .foregroundStyle(AntiqueTheme.ink)
                        .textSelection(.enabled)
                    Text("Denna avläsning görs utan språklig rättning för att minska risken att bokstäver och sifferkoder ändras. Jämför alltid med bilden.")
                        .font(.system(size: 11, design: .serif))
                        .foregroundStyle(AntiqueTheme.mutedInk)
                }
            }

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

            if !markingManufacturerMatches.isEmpty {
                VStack(alignment: .leading, spacing: 9) {
                    Text("MÖJLIGA TILLVERKARTRÄFFAR")
                        .font(.system(size: 10, weight: .semibold, design: .serif))
                        .tracking(1)
                        .foregroundStyle(AntiqueTheme.brass)
                    ForEach(markingManufacturerMatches, id: \.maker) { match in
                        VStack(alignment: .leading, spacing: 3) {
                            Text(match.maker)
                                .font(.system(size: 15, weight: .semibold, design: .serif))
                                .foregroundStyle(AntiqueTheme.forest)
                            Text(match.note)
                                .font(.system(size: 12, design: .serif))
                                .foregroundStyle(AntiqueTheme.ink)
                            Text("Träff i avläst märkning: “\(match.matchedText)”")
                                .font(.system(size: 11, design: .monospaced))
                                .foregroundStyle(AntiqueTheme.mutedInk)
                            if let sourceURL = match.sourceURL, let url = URL(string: sourceURL) {
                                let sourceLabel = match.sourceTitle ?? "referens"
                                Link("Öppna källan: \(sourceLabel)", destination: url)
                                    .font(.system(size: 11, weight: .medium, design: .serif))
                                    .foregroundStyle(AntiqueTheme.forest)
                            }
                        }
                    }
                    Text("Träffarna bygger enbart på OCR-text och kan vara fellästa eller avse något annat än tillverkaren. Källänkarna ger historisk bakgrund – de verifierar inte att just ditt föremål är äkta, tillverkat av märket eller från en viss period. Enstaka ortsnamn och korta bokstavskombinationer räcker inte som bevis. Kontrollera hela stämpeln, placeringen, godset och originalbilden.")
                        .font(.system(size: 11, design: .serif))
                        .foregroundStyle(AntiqueTheme.mutedInk)
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

    private var markingManufacturerMatches: [(maker: String, note: String, matchedText: String, sourceTitle: String?, sourceURL: String?)] {
        let source = [rawMarkingText, recognizedText]
            .filter { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
            .joined(separator: "\\n")
        let normalizedSource = source.folding(options: [.diacriticInsensitive, .caseInsensitive], locale: .current)
        let references: [(maker: String, aliases: [String], note: String, sourceTitle: String?, sourceURL: String?)] = [
            ("Rörstrand", ["Rörstrand"], "Svensk porslinsfabrik grundad 1726. Rörstrands museum beskriver flera märkningsepoker: tidiga Stockholm/Rörstrand-märkningar, kronstämpeln från 1884 och ett krönt R från 2000. En OCR-träff på namnet daterar inte föremålet i sig.", "Rörstrand Museum – Stämplar", "https://rorstrand-museum.se/stamplar/"),
            ("Gustavsberg", ["Gustavsberg"], "Porslinsfabriken grundades 1825. Den klassiska ankarmärkningen infördes 1839. Kontrollera ankarets utformning och eventuell formgivar- eller modellmärkning mot föremålet.", "Gustafsbergs Porslinsfabrik – Historik", "https://www.gustavsberg.com/se/om-oss/var-historia"),
            ("Gefle", ["Gefle"], "Namn som förekommer på svenskt porslin. OCR-träffen är endast en ledtråd; jämför hela stämpeln, dekor och föremålets form.", nil, nil),
            ("Upsala-Ekeby", ["Upsala-Ekeby", "Upsala Ekeby"], "Svensk keramik- och porslinstillverkare. Jämför hela märkningen, modell och dekor; OCR-träffen verifierar inte fabrikat.", nil, nil),
            ("Höganäs", ["Höganäs", "Hoganas"], "Namn förknippat med svensk keramik. Kontrollera om märkningen avser fabrik, ort eller senare återförsäljning.", nil, nil),
            ("Jie Gantofta", ["Jie Gantofta"], "Svensk keramikproducent. Enbart bokstäverna JIE räcker inte för säker identifiering; jämför hela logotypen och stämpelns utformning.", nil, nil),
            ("Nittsjö", ["Nittsjö", "Nittsjo"], "Svensk keramikproducent. Jämför stämpel, form och eventuell modellbeteckning.", nil, nil),
            ("Bo Fajans", ["Bo Fajans"], "Svensk fajans- och keramikproducent. Kontrollera stämpelvariant och dekor.", nil, nil),
            ("Kosta", ["Kosta Glasbruk", "Kosta Boda"], "Kosta glasbruk grundades 1742. Kosta Boda som varumärke växte fram genom sammanslagningen av glasbruken Kosta, Boda och Åfors. En OCR-träff daterar inte glaset; jämför gravyr, etikett, formgivarsignatur och modellnummer.", "Kosta Boda – Historia", "https://www.kostaboda.se/historia"),
            ("Boda", ["Boda Glasbruk"], "Svenskt glasbruk. En ensam OCR-träff på ordet Boda är för tvetydig; jämför hela märkningen.", nil, nil),
            ("Orrefors", ["Orrefors"], "Orrefors började tillverka glas i slutet av 1800-talet och kristallglas 1914. Formgivarna Simon Gate och Edward Hald knöts till bruket 1916–1917. Använd detta som historisk kontext; märkningen måste jämföras med föremålets signatur och modell.", "Orrefors Museum – Glashistoria", "https://www.orreforsmuseum.se/om-oss/orrefors-historia/"),
            ("Skruf", ["Skruf"], "Svenskt glasbruk. Kontrollera signatur och eventuell modellbeteckning.", nil, nil),
            ("Målerås", ["Målerås", "Maleras"], "Svenskt glasbruk. Kontrollera signatur, etikett och formgivare.", nil, nil),
            ("Iittala", ["Iittala"], "Finskt glas- och designvarumärke. Jämför etikett, signatur och formgivare.", nil, nil),
            ("Nuutajärvi", ["Nuutajärvi", "Nuutajarvi"], "Finskt glasbruk. Kontrollera etikett, signatur och modell.", nil, nil),
            ("Riihimäen Lasi", ["Riihimäen Lasi", "Riihimaen Lasi"], "Finskt glasbruk. Jämför märkning och föremålets form.", nil, nil),
            ("Arabia", ["Arabia"], "Finsk porslinstillverkare. Fabriksmärkena har ändrats i flera omgångar; jämför hela logotypen, texten MADE IN FINLAND, färg och eventuell sifferkod. Ordet ARABIA ensamt räcker inte för datering.", "Arabia – översikt över fabriksmärken (PDF)", "https://finnishdesign.com/wp-content/uploads/2023/05/Arabia_factorymarkings-5185317.pdf"),
            ("Royal Copenhagen", ["Royal Copenhagen"], "Dansk porslinstillverkare. Kontrollera kronstämpel och övriga underglasyrmärken.", nil, nil),
            ("Bing & Grøndahl", ["Bing & Grøndahl", "Bing & Grondahl", "Bing og Grondahl"], "Dansk porslinstillverkare. Jämför de tre tornen och stämpelns utformning.", nil, nil),
            ("Holmegaard", ["Holmegaard"], "Danskt glasbruk. Kontrollera signatur, etikett och modell.", nil, nil)
        ]

        return references.compactMap { reference in
            for alias in reference.aliases {
                let normalizedAlias = alias.folding(options: [.diacriticInsensitive, .caseInsensitive], locale: .current)
                let escapedAlias = NSRegularExpression.escapedPattern(for: normalizedAlias)
                let pattern = "(?<![\\p{L}\\p{N}])" + escapedAlias + "(?![\\p{L}\\p{N}])"
                guard let expression = try? NSRegularExpression(pattern: pattern),
                      expression.firstMatch(in: normalizedSource, range: NSRange(normalizedSource.startIndex..., in: normalizedSource)) != nil else { continue }
                return (reference.maker, reference.note, alias, reference.sourceTitle, reference.sourceURL)
            }
            return nil
        }
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

    private func inspectionSummary(for clue: String) -> String {
        let category = clue.lowercased()
        if category.contains("figurin") || category.contains("skulptur") || category.contains("djurmotiv") || category.contains("hästmotiv") || category.contains("hundmotiv") || category.contains("kattmotiv") || category.contains("fågelmotiv") {
            return "Granska modelleringen av huvud, ben och detaljer, hur figuren står eller är monterad samt om den är ihålig eller massiv. Undersök undersida, eventuella gjutskarvar, bemålning och signatur."
        }
        if category.contains("glas") || category.contains("flaska") {
            return "Granska mynning, botten, sömmar, luftbubblor och eventuell slipning eller gravyr. Fotografera mot både ljus och mörk bakgrund."
        }
        if category.contains("keramik") || category.contains("porslin") || category.contains("vas") || category.contains("skål") || category.contains("tallrik") || category.contains("kopp") || category.contains("kruk") || category.contains("servis") {
            return "Granska gods, glasyr, dekor, fotring och undersida. Leta efter stämpel, drej- eller formspår, krackelering, nagg och lagningar."
        }
        if category.contains("möbel") || category.contains("stol") || category.contains("bord") || category.contains("skåp") {
            return "Kontrollera först att bilden faktiskt visar en möbel och inte ett föremål fotograferat på ett bord. Om det är en möbel: granska sammanfogningar, träslag, fanér, beslag, lådor och undersida. Leta efter etiketter, märkningar och senare reparationer."
        }
        if category.contains("målning") || category.contains("bild") || category.contains("tavla") {
            return "Granska signatur, färgskikt, underlag, ram och baksida. Fotografera etiketter och eventuella verkstads- eller utställningsmärken."
        }
        if category.contains("klock") || category.contains("ur") {
            return "Granska urtavla, visare, boett, serienummer och verk. Öppna inte boetten om det riskerar att skada föremålet."
        }
        if category.contains("smycke") || category.contains("ring") || category.contains("brosch") {
            return "Granska infattningar, lås, lödningar och stämplar. Metallhalt och äkthet kan inte avgöras säkert enbart från fotografi."
        }
        return "Dokumentera form, konstruktion, materialdetaljer och märkningar. Ta bilder av fram- och baksida samt undersida innan du drar slutsatser."
    }

    private func inspectionSuggestions(for clue: String?) -> [String] {
        let category = clue?.lowercased() ?? ""
        if category.contains("figurin") || category.contains("skulptur") || category.contains("djurmotiv") || category.contains("hästmotiv") || category.contains("hundmotiv") || category.contains("kattmotiv") || category.contains("fågelmotiv") {
            return ["Fotografera figuren framifrån, från sidan och bakifrån", "Visa undersidan, eventuell signatur och gjut- eller formskarvar", "Ta närbilder av bemålning, slitage, sprickor och lagningar"]
        }
        if category.contains("glas") || category.contains("flaska") {
            return ["Fotografera eventuell signatur eller etikett nära foten", "Visa botten, mynning och glastjocklek", "Ta bilder i både genomfallande och snett sidoljus"]
        }
        if category.contains("vas") || category.contains("keramik") || category.contains("porslin") || category.contains("skål") || category.contains("tallrik") || category.contains("kopp") || category.contains("kruk") || category.contains("servis") {
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

        let cgOrientation = Self.visionOrientation(for: image.imageOrientation)
        isRecognizingText = true
        recognitionError = nil
        recognizedText = ""
        imageClues = []
        imageClueDetails = []
        primaryClue = nil
        rawMarkingText = ""


        DispatchQueue.global(qos: .userInitiated).async {
            let readingRequest = VNRecognizeTextRequest()
            readingRequest.recognitionLevel = .accurate
            readingRequest.usesLanguageCorrection = true
            readingRequest.recognitionLanguages = ["sv-SE", "en-US"]

            // A second pass without language correction can preserve stamp codes,
            // initials and serial numbers that autocorrection might otherwise alter.
            let markingRequest = VNRecognizeTextRequest()
            markingRequest.recognitionLevel = .accurate
            markingRequest.usesLanguageCorrection = false
            markingRequest.recognitionLanguages = ["sv-SE", "en-US"]

            // A dedicated lower-image pass helps capture maker marks commonly
            // placed on the foot, base or reverse of ceramics and glass.
            let baseMarkingRequest = VNRecognizeTextRequest()
            baseMarkingRequest.recognitionLevel = .accurate
            baseMarkingRequest.usesLanguageCorrection = false
            baseMarkingRequest.recognitionLanguages = ["sv-SE", "en-US"]
            baseMarkingRequest.regionOfInterest = CGRect(x: 0, y: 0, width: 1, height: 0.48)

            let classification = VNClassifyImageRequest()

            do {
                let handler = VNImageRequestHandler(cgImage: cgImage, orientation: cgOrientation)
                try handler.perform([readingRequest, markingRequest, baseMarkingRequest, classification])
                let lines = (readingRequest.results ?? []).compactMap { $0.topCandidates(1).first?.string }
                let result = lines.joined(separator: "\n")
                let rawLines = (markingRequest.results ?? []).compactMap { $0.topCandidates(1).first?.string }
                let baseLines = (baseMarkingRequest.results ?? []).compactMap { $0.topCandidates(1).first?.string }
                let uniqueRawLines = Array(NSOrderedSet(array: rawLines + baseLines)) as? [String] ?? rawLines
                let rawResult = uniqueRawLines.joined(separator: "\n")
                // Keep only useful object and motif clues. Vision confidence is
                // not an identification probability, so never present it as one.
                let rankedResults = (classification.results ?? [])
                    .filter { $0.confidence >= 0.10 }
                    .compactMap { result -> (label: String, confidence: Float)? in
                        guard let label = Self.localizedClue(result.identifier) else { return nil }
                        return (label, result.confidence)
                    }
                    .prefix(3)
                let clues = rankedResults.map { $0.label }
                let clueDetails = rankedResults.map { $0.label }
                let leadingClue = rankedResults.first?.label

                DispatchQueue.main.async {
                    recognizedText = result
                    imageClues = Array(clues)
                    imageClueDetails = Array(clueDetails)
                    primaryClue = leadingClue
                    rawMarkingText = rawResult
                    if result.isEmpty && rawResult.isEmpty && clues.isEmpty {
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

    private static func visionOrientation(for orientation: UIImage.Orientation) -> CGImagePropertyOrientation {
        switch orientation {
        case .up: return .up
        case .upMirrored: return .upMirrored
        case .down: return .down
        case .downMirrored: return .downMirrored
        case .left: return .left
        case .leftMirrored: return .leftMirrored
        case .right: return .right
        case .rightMirrored: return .rightMirrored
        @unknown default: return .up
        }
    }

    private static func localizedClue(_ identifier: String) -> String? {
        // Vision labels can be hierarchical (for example "tableware, plate").
        // Match complete label components, not arbitrary substrings: otherwise
        // "tableware" can incorrectly become "Bord".
        let components = identifier.lowercased()
            .split(separator: ",")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
        let terms: [(String, String)] = [
            ("tableware", "Tallrik / servis"), ("dinnerware", "Tallrik / servis"),
            ("plate", "Tallrik"), ("platter", "Serveringsfat"), ("dish", "Fat / tallrik"),
            ("china", "Porslin"), ("porcelain", "Porslin"),
            ("ceramic", "Keramik"),
            ("pottery", "Keramik"), ("bowl", "Skål"),
            ("cup", "Kopp"), ("mug", "Mugg"),
            // Motifs are deliberately not treated as object identities.
            // A bird painted on a plate must not turn the plate into a bird.
            ("figurine", "Figurin"),
            ("statuette", "Figurin"), ("sculpture", "Skulptur"),
            ("statue", "Skulptur"), ("vase", "Vas"), ("urn", "Urna"),
            ("teapot", "Tekanna"), ("pitcher", "Kanna"), ("jug", "Kanna"),
            ("bottle", "Flaska"), ("glass", "Glasföremål"),
            ("clock", "Klocka"), ("watch", "Armbandsur"),
            ("lamp", "Lampa"), ("chair", "Stol"),
            // "table" is too ambiguous in object photographs and caused
            // tableware photographed on a table to be misreported as furniture.
            ("cabinet", "Skåp"), ("furniture", "Möbel"),
            ("painting", "Målning"), ("artwork", "Konstverk"),
            ("jewelry", "Smycke"), ("ring", "Ring"), ("brooch", "Brosch"),
            ("coin", "Mynt"), ("book", "Bok")
        ]
        return terms.first(where: { components.contains($0.0) })?.1
    }
}

private extension CGImagePropertyOrientation {
    init(_ orientation: UIImage.Orientation) {
        switch orientation {
        case .up: self = .up
        case .down: self = .down
        case .left: self = .left
        case .right: self = .right
        case .upMirrored: self = .upMirrored
        case .downMirrored: self = .downMirrored
        case .leftMirrored: self = .leftMirrored
        case .rightMirrored: self = .rightMirrored
        @unknown default: self = .up
        }
    }
}

private struct CollectionImageMatch: Identifiable {
    let id = UUID()
    let title: String
    let distance: Float
}

private struct SaveAntiqueSheet: View {
    @EnvironmentObject private var collection: CollectionStore
    @Environment(\.dismiss) private var dismiss
    let image: UIImage
    let recognizedText: String

    @State private var title = ""
    @State private var maker = ""
    @State private var estimatedPeriod = ""
    @State private var materials = ""
    @State private var markings = ""
    @State private var conditionNotes = ""
    @State private var provenance = ""
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
                        field("Ungefärlig tidsperiod", placeholder: "Exempelvis omkring 1920", text: $estimatedPeriod)
                        field("Material", placeholder: "Exempelvis porslin, mässing, ek …", text: $materials)
                        field("Stämplar och signaturer", placeholder: "Skriv av exakt eller beskriv märkningen", text: $markings)
                        field("Skick och mått", placeholder: "Slitage, skador, lagningar, höjd/bredd …", text: $conditionNotes)
                        field("Ursprung och proveniens", placeholder: "Tidigare ägare, inköpsplats eller historia", text: $provenance)
                        field("Inköpspris i kronor", placeholder: "Lämna tomt om okänt", text: $purchasePrice)
                            .keyboardType(.decimalPad)

                        Text("Fyll bara i det du känner till. Okända uppgifter kan lämnas tomma – det är bättre än att gissa.")
                            .font(.system(size: 12, design: .serif))
                            .foregroundStyle(AntiqueTheme.mutedInk)

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
            try collection.add(title: title, maker: maker, notes: combinedNotes, purchasePrice: purchasePrice, image: image, estimatedPeriod: estimatedPeriod, materials: materials, markings: markings, conditionNotes: conditionNotes, provenance: provenance)
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


private struct MetSearchResponse: Decodable {
    let objectIDs: [Int]?
}

private struct MetMuseumObject: Decodable, Identifiable {
    let objectID: Int
    let title: String
    let artistDisplayName: String
    let objectDate: String
    let medium: String
    let department: String
    let objectURL: String
    let isPublicDomain: Bool
    var id: Int { objectID }
}

private enum MetSearchError: Error {
    case invalidURL
}
