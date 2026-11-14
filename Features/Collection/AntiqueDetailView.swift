import SwiftUI
import PhotosUI
import UIKit

struct AntiqueDetailView: View {
    @EnvironmentObject private var collection: CollectionStore
    @Environment(\.dismiss) private var dismiss
    @State private var item: SavedAntique
    @State private var selectedImages: [PhotosPickerItem] = []
    @State private var showingEvidenceForm = false
    @State private var evidenceToEdit: SavedPriceEvidence?
    @State private var showingDeleteConfirmation = false
    @State private var message: String?
    @State private var exportedPDF: URL?

    init(item: SavedAntique) {
        _item = State(initialValue: item)
    }

    var body: some View {
        ZStack {
            PaperBackground()
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 22) {
                    imageGallery

                    VStack(alignment: .leading, spacing: 5) {
                        eyebrow("FÖREMÅLSKATALOG")
                        Text(item.title.isEmpty ? "Namnlöst föremål" : item.title)
                            .font(AntiqueTheme.title(30))
                            .foregroundStyle(AntiqueTheme.forest)
                        if !item.maker.isEmpty {
                            Text(item.maker)
                                .font(.system(size: 16, design: .serif).italic())
                                .foregroundStyle(AntiqueTheme.walnut)
                        }
                    }

                    section("Grunduppgifter") {
                        editField("Föremålets namn", text: $item.title)
                        editField("Tillverkare / konstnär", text: $item.maker)
                        editField("Trolig tidsperiod", text: $item.estimatedPeriod)
                        editField("Material", text: $item.materials)
                        editField("Inköpspris (kr)", text: $item.purchasePrice)
                            .keyboardType(.decimalPad)
                    }

                    section("Märkningar och kännetecken") {
                        editArea("Stämplar, signaturer och etiketter", text: $item.markings,
                                 hint: "Beskriv exakt vad som står eller syns …")
                    }

                    section("Skick och proveniens") {
                        editArea("Skick och eventuella skador", text: $item.conditionNotes,
                                 hint: "Sprickor, lagningar, slitage, renoveringar …")
                        editArea("Historik och proveniens", text: $item.provenance,
                                 hint: "Tidigare ägare, inköpsplats, dokumentation …")
                        editArea("Övriga anteckningar", text: $item.notes,
                                 hint: "Mått, detaljer och egna observationer …")
                    }

                    valuationSection

                    messageView
                    saveButton
                }
                .padding(.horizontal, 20)
                .padding(.top, 18)
            }
        }
        .navigationTitle("Föremål")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    Button {
                        exportCatalogSheet()
                    } label: {
                        Label("Exportera katalogblad som PDF", systemImage: "doc.richtext")
                    }
                    Button(role: .destructive) {
                        showingDeleteConfirmation = true
                    } label: {
                        Label("Radera föremål", systemImage: "trash")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                        .foregroundStyle(AntiqueTheme.forest)
                }
            }
        }
        .sheet(item: $exportedPDF) { url in
            ActivityShareSheet(activityItems: [url])
                .presentationDetents([.medium, .large])
        }
        .confirmationDialog("Radera föremålet ur samlingen?", isPresented: $showingDeleteConfirmation, titleVisibility: .visible) {
            Button("Radera", role: .destructive, action: deleteItem)
            Button("Avbryt", role: .cancel) {}
        } message: {
            Text("Bilder, anteckningar och prisunderlag tas bort från den här enheten.")
        }
        .sheet(isPresented: $showingEvidenceForm) {
            AddEvidenceSheet { evidence in
                item.evidence.insert(evidence, at: 0)
                save()
            }
            .presentationDetents([.medium, .large])
            .presentationDragIndicator(.visible)
        }
        .sheet(item: $evidenceToEdit) { evidence in
            AddEvidenceSheet(evidence: evidence) { updated in
                if let index = item.evidence.firstIndex(where: { $0.id == updated.id }) {
                    item.evidence[index] = updated
                    save()
                }
            }
            .presentationDetents([.medium, .large])
            .presentationDragIndicator(.visible)
        }
        .onChange(of: selectedImages) { _, newItems in
            Task {
                await importSelectedImages(newItems)
            }
        }
    }

    @MainActor
    private func importSelectedImages(_ photos: [PhotosPickerItem]) async {
        for photo in photos {
            guard let data = try? await photo.loadTransferable(type: Data.self) else { continue }
            guard let image = UIImage(data: data) else { continue }
            do {
                try collection.addImage(image, to: item.id)
                refreshItemFromCollection()
            } catch {
                message = error.localizedDescription
            }
        }
        selectedImages = []
    }

    private func refreshItemFromCollection() {
        let currentID = item.id
        if let refreshedItem = collection.items.first(where: { candidate in
            candidate.id == currentID
        }) {
            item = refreshedItem
        }
    }

    private var imageGallery: some View {
        VStack(alignment: .leading, spacing: 10) {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(Array(item.allImageFileNames.enumerated()), id: \.offset) { index, filename in
                        Group {
                            if let image = collection.image(named: filename) {
                                Image(uiImage: image)
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 270, height: 250)
                                    .background(AntiqueTheme.parchment)
                            } else {
                                ZStack {
                                    AntiqueTheme.parchment
                                    Image(systemName: "photo")
                                        .font(.largeTitle)
                                        .foregroundStyle(AntiqueTheme.brass)
                                }
                                .frame(width: 270, height: 250)
                            }
                        }
                        .overlay(alignment: .topTrailing) {
                            if index > 0 {
                                Button {
                                    removePhoto(filename)
                                } label: {
                                    Image(systemName: "trash")
                                        .font(.system(size: 12, weight: .semibold))
                                        .foregroundStyle(.white)
                                        .padding(9)
                                        .background(AntiqueTheme.walnut.opacity(0.9), in: Circle())
                                }
                                .padding(9)
                                .accessibilityLabel("Ta bort bilden")
                            } else {
                                Text("Omslagsbild")
                                    .font(.system(size: 10, weight: .medium, design: .serif))
                                    .foregroundStyle(AntiqueTheme.parchment)
                                    .padding(.horizontal, 9)
                                    .padding(.vertical, 6)
                                    .background(AntiqueTheme.forest.opacity(0.92))
                                    .padding(9)
                            }
                        }
                        .overlay(Rectangle().stroke(AntiqueTheme.brass.opacity(0.65), lineWidth: 1))
                    }
                }
            }

            PhotosPicker(selection: $selectedImages, maxSelectionCount: 8, matching: .images) {
                Label("Lägg till fler bilder", systemImage: "plus")
                    .font(.system(size: 13, design: .serif))
                    .foregroundStyle(AntiqueTheme.forest)
            }
        }
    }

    @ViewBuilder
    private var messageView: some View {
        if let message {
            Text(message)
                .font(.system(size: 13, design: .serif))
                .foregroundStyle(AntiqueTheme.forest)
        }
    }

    private var saveButton: some View {
        Button(action: save) {
            Label("Spara ändringar", systemImage: "checkmark")
                .font(.system(size: 16, weight: .medium, design: .serif))
                .foregroundStyle(AntiqueTheme.parchment)
                .frame(maxWidth: .infinity)
                .padding(15)
                .background(AntiqueTheme.forest)
                .clipShape(RoundedRectangle(cornerRadius: 5))
        }
        .padding(.top, 4)
        .padding(.bottom, 28)
    }

    private var valuationSection: some View {
        section("Värderingsunderlag") {
            Text("Egen uppskattning – inte en automatisk marknadsvärdering.")
                .font(.system(size: 12, design: .serif))
                .foregroundStyle(AntiqueTheme.mutedInk)
            editField("Lägre värde (kr)", text: $item.valuationLow)
                .keyboardType(.decimalPad)
            editField("Högre värde (kr)", text: $item.valuationHigh)
                .keyboardType(.decimalPad)
            editArea("Kommentar till uppskattningen", text: $item.valuationNotes,
                     hint: "Vad bygger bedömningen på? Skick, jämförelseobjekt …")

            BrassDivider()
            HStack {
                Text("Jämförelseobjekt och källor")
                    .font(AntiqueTheme.title(18))
                    .foregroundStyle(AntiqueTheme.forest)
                Spacer()
                Button {
                    showingEvidenceForm = true
                } label: {
                    Image(systemName: "plus.circle")
                        .font(.title3)
                        .foregroundStyle(AntiqueTheme.brass)
                }
            }

            if item.evidence.isEmpty {
                Text("Inga prisreferenser tillagda. Lägg bara in uppgifter du kan koppla till en källa.")
                    .font(.system(size: 12, design: .serif))
                    .foregroundStyle(AntiqueTheme.mutedInk)
            } else {
                ForEach(item.evidence) { evidence in
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text(evidence.kind.title.uppercased())
                                .font(.system(size: 9, weight: .semibold, design: .serif))
                                .tracking(1)
                                .foregroundStyle(AntiqueTheme.brass)
                            Spacer()
                            Text(evidence.amount + " kr")
                                .font(.system(size: 15, weight: .medium, design: .serif))
                                .foregroundStyle(AntiqueTheme.forest)
                        }
                        Text(evidence.sourceName)
                            .font(.system(size: 14, design: .serif))
                            .foregroundStyle(AntiqueTheme.ink)
                        if let date = evidence.date {
                            Text(date.formatted(date: .long, time: .omitted))
                                .font(.system(size: 11, design: .serif))
                                .foregroundStyle(AntiqueTheme.mutedInk)
                        }
                        if !evidence.url.isEmpty {
                            if let url = URL(string: evidence.url), ["http", "https"].contains(url.scheme?.lowercased() ?? "") {
                                Link(destination: url) {
                                    Label("Öppna källan", systemImage: "arrow.up.right.square")
                                        .font(.system(size: 11, design: .serif))
                                }
                                .tint(AntiqueTheme.forest)
                            } else {
                                Text(evidence.url)
                                    .font(.system(size: 11, design: .serif))
                                    .foregroundStyle(AntiqueTheme.mutedInk)
                                    .textSelection(.enabled)
                            }
                        }
                        if !evidence.notes.isEmpty {
                            Text(evidence.notes)
                                .font(.system(size: 12, design: .serif))
                                .foregroundStyle(AntiqueTheme.mutedInk)
                        }
                    }
                    .padding(.vertical, 8)
                    .onTapGesture {
                        evidenceToEdit = evidence
                    }
                    .contextMenu {
                        Button {
                            evidenceToEdit = evidence
                        } label: {
                            Label("Redigera prisreferens", systemImage: "pencil")
                        }
                        Button(role: .destructive) {
                            item.evidence.removeAll { $0.id == evidence.id }
                            save()
                        } label: {
                            Label("Ta bort prisreferens", systemImage: "trash")
                        }
                    }
                    BrassDivider()
                }
            }
        }
    }

    private func section<Content: View>(_ title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(AntiqueTheme.title(22))
                .foregroundStyle(AntiqueTheme.forest)
            BrassDivider()
            content()
        }
    }

    private func editField(_ title: String, text: Binding<String>) -> some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(title)
                .font(.system(size: 12, weight: .medium, design: .serif))
                .foregroundStyle(AntiqueTheme.walnut)
            TextField(title, text: text)
                .font(.system(size: 14, design: .serif))
                .padding(11)
                .background(AntiqueTheme.parchment.opacity(0.65))
                .overlay(RoundedRectangle(cornerRadius: 4).stroke(AntiqueTheme.brass.opacity(0.4)))
        }
    }

    private func editArea(_ title: String, text: Binding<String>, hint: String) -> some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(title)
                .font(.system(size: 12, weight: .medium, design: .serif))
                .foregroundStyle(AntiqueTheme.walnut)
            TextField(hint, text: text, axis: .vertical)
                .font(.system(size: 14, design: .serif))
                .lineLimit(3...6)
                .padding(11)
                .background(AntiqueTheme.parchment.opacity(0.65))
                .overlay(RoundedRectangle(cornerRadius: 4).stroke(AntiqueTheme.brass.opacity(0.4)))
        }
    }

    private func eyebrow(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 9, weight: .semibold, design: .serif))
            .tracking(2)
            .foregroundStyle(AntiqueTheme.brass)
    }


    private func exportCatalogSheet() {
        do {
            let url = try AntiqueCatalogPDF.create(item: item, coverImage: collection.image(for: item))
            exportedPDF = url
        } catch {
            message = "PDF-filen kunde inte skapas: \\(error.localizedDescription)"
        }
    }

    private func removePhoto(_ filename: String) {
        do {
            try collection.removeAdditionalImage(filename, from: item.id)
            if let refreshed = collection.items.first(where: { $0.id == item.id }) {
                item = refreshed
            }
            message = "Bilden har tagits bort."
        } catch {
            message = error.localizedDescription
        }
    }

    private func save() {
        do {
            try collection.update(item)
            message = "Ändringarna är sparade."
        } catch {
            message = error.localizedDescription
        }
    }

    private func deleteItem() {
        do {
            try collection.delete(item)
            dismiss()
        } catch {
            message = error.localizedDescription
        }
    }
}

private struct AddEvidenceSheet: View {
    @Environment(\.dismiss) private var dismiss
    let onAdd: (SavedPriceEvidence) -> Void

    @State private var sourceName: String
    @State private var amount: String
    @State private var kind: SavedPriceEvidence.EvidenceKind
    @State private var url: String
    @State private var notes: String
    @State private var evidenceDate: Date

    init(evidence: SavedPriceEvidence? = nil, onAdd: @escaping (SavedPriceEvidence) -> Void) {
        self.onAdd = onAdd
        _sourceName = State(initialValue: evidence?.sourceName ?? "")
        _amount = State(initialValue: evidence?.amount ?? "")
        _kind = State(initialValue: evidence?.kind ?? .realizedSale)
        _url = State(initialValue: evidence?.url ?? "")
        _notes = State(initialValue: evidence?.notes ?? "")
        _evidenceDate = State(initialValue: evidence?.date ?? Date())
        _editingID = State(initialValue: evidence?.id)
    }

    @State private var editingID: UUID?

    var body: some View {
        NavigationStack {
            ZStack {
                PaperBackground()
                ScrollView {
                    VStack(alignment: .leading, spacing: 14) {
                        Text(editingID == nil ? "Lägg till prisreferens" : "Redigera prisreferens")
                            .font(AntiqueTheme.title(26))
                            .foregroundStyle(AntiqueTheme.forest)
                        field("Auktionshus / källa", text: $sourceName)
                        field("Pris i kronor", text: $amount)
                            .keyboardType(.decimalPad)

                        VStack(alignment: .leading, spacing: 5) {
                            Text("Typ av prisuppgift")
                                .font(.system(size: 12, weight: .medium, design: .serif))
                                .foregroundStyle(AntiqueTheme.walnut)
                            Picker("Typ", selection: $kind) {
                                ForEach(SavedPriceEvidence.EvidenceKind.allCases) { value in
                                    Text(value.title).tag(value)
                                }
                            }
                            .tint(AntiqueTheme.forest)
                        }

                        DatePicker("Datum för prisuppgiften", selection: $evidenceDate, displayedComponents: .date)
                            .font(.system(size: 13, design: .serif))
                            .tint(AntiqueTheme.forest)

                        field("Länk till källan (om finns)", text: $url)
                        VStack(alignment: .leading, spacing: 5) {
                            Text("Anteckning")
                                .font(.system(size: 12, weight: .medium, design: .serif))
                                .foregroundStyle(AntiqueTheme.walnut)
                            TextField("Datum, skick, modell och jämförbarhet …", text: $notes, axis: .vertical)
                                .lineLimit(2...4)
                                .padding(11)
                                .background(AntiqueTheme.parchment.opacity(0.7))
                        }
                        Text("Ett begärt pris är inte samma sak som ett faktiskt försäljningspris. Välj rätt kategori.")
                            .font(.system(size: 12, design: .serif))
                            .foregroundStyle(AntiqueTheme.mutedInk)
                    }
                    .padding(22)
                }
            }
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Avbryt") { dismiss() }.foregroundStyle(AntiqueTheme.forest)
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button(editingID == nil ? "Lägg till" : "Spara") {
                        onAdd(SavedPriceEvidence(id: editingID ?? UUID(),
                                                 sourceName: sourceName.trimmingCharacters(in: .whitespacesAndNewlines),
                                                 amount: amount.trimmingCharacters(in: .whitespacesAndNewlines),
                                                 kind: kind, date: evidenceDate, url: url.trimmingCharacters(in: .whitespacesAndNewlines),
                                                 notes: notes.trimmingCharacters(in: .whitespacesAndNewlines)))
                        dismiss()
                    }
                    .disabled(sourceName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || amount.isEmpty)
                    .foregroundStyle(AntiqueTheme.forest)
                }
            }
        }
    }

    private func field(_ title: String, text: Binding<String>) -> some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(title)
                .font(.system(size: 12, weight: .medium, design: .serif))
                .foregroundStyle(AntiqueTheme.walnut)
            TextField(title, text: text)
                .padding(11)
                .background(AntiqueTheme.parchment.opacity(0.7))
        }
    }
}


private struct ActivityShareSheet: UIViewControllerRepresentable {
    let activityItems: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
    }

    func updateUIViewController(_ controller: UIActivityViewController, context: Context) {}
}

private enum AntiqueCatalogPDF {
    static func create(item: SavedAntique, coverImage: UIImage?) throws -> URL {
        let page = CGRect(x: 0, y: 0, width: 612, height: 792)
        let renderer = UIGraphicsPDFRenderer(bounds: page)
        let filename = "Antikspanaren-\(item.title.replacingOccurrences(of: "/", with: "-")).pdf"
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(filename)
        let ink = UIColor(red: 0.12, green: 0.16, blue: 0.13, alpha: 1)
        let green = UIColor(red: 0.055, green: 0.145, blue: 0.105, alpha: 1)
        let brass = UIColor(red: 0.76, green: 0.59, blue: 0.30, alpha: 1)
        let paper = UIColor(red: 0.96, green: 0.93, blue: 0.86, alpha: 1)

        let body = [
            ("TILLVERKARE / KONSTNÄR", item.maker),
            ("TIDSPERIOD", item.estimatedPeriod),
            ("MATERIAL", item.materials),
            ("MÄRKNINGAR OCH KÄNNETECKEN", item.markings),
            ("SKICK", item.conditionNotes),
            ("HISTORIK OCH PROVENIENS", item.provenance),
            ("INKÖPSPRIS", item.purchasePrice.isEmpty ? "" : item.purchasePrice + " kr"),
            ("EGEN VÄRDEUPPSKATTNING", [item.valuationLow, item.valuationHigh].filter { !$0.isEmpty }.joined(separator: " – ") + ((item.valuationLow.isEmpty && item.valuationHigh.isEmpty) ? "" : " kr")),
            ("KOMMENTAR TILL UPPSKATTNINGEN", item.valuationNotes),
            ("ANTECKNINGAR", item.notes)
        ].filter { !$0.1.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }

        let evidenceText = item.evidence.map { evidence in
            "\(evidence.kind.title): \(evidence.amount) kr · \(evidence.sourceName)\(evidence.date.map { " · " + $0.formatted(date: .numeric, time: .omitted) } ?? "")\n\(evidence.notes)"
        }.joined(separator: "\n\n")

        let text = body.map { "\($0.0)\n\($0.1)" }.joined(separator: "\n\n")
            + (evidenceText.isEmpty ? "" : "\n\nPRISREFERENSER OCH KÄLLOR\n\(evidenceText)")
        let data = renderer.pdfData { context in
            context.beginPage()
            paper.setFill()
            context.cgContext.fill(page)
            brass.setStroke()
            context.cgContext.setLineWidth(1)
            context.cgContext.stroke(page.insetBy(dx: 28, dy: 28))

            let masthead = "ANTIKSPANAREN  ·  FÖREMÅLSKATALOG"
            (masthead as NSString).draw(at: CGPoint(x: 46, y: 44), withAttributes: [
                .font: UIFont(name: "Georgia-Bold", size: 9) ?? UIFont.boldSystemFont(ofSize: 9),
                .foregroundColor: brass,
                .kern: 1.5
            ])

            var y: CGFloat = 70
            if let coverImage {
                let imageRect = CGRect(x: 46, y: y, width: 150, height: 145)
                let ratio = min(imageRect.width / coverImage.size.width, imageRect.height / coverImage.size.height)
                let size = CGSize(width: coverImage.size.width * ratio, height: coverImage.size.height * ratio)
                coverImage.draw(in: CGRect(x: imageRect.midX - size.width / 2, y: imageRect.midY - size.height / 2, width: size.width, height: size.height))
                y += 160
            }

            let titleAttributes: [NSAttributedString.Key: Any] = [
                .font: UIFont(name: "Georgia", size: 25) ?? UIFont.systemFont(ofSize: 25),
                .foregroundColor: green
            ]
            (item.title as NSString).draw(in: CGRect(x: 46, y: y, width: 520, height: 38), withAttributes: titleAttributes)
            y += 48

            let paragraph = NSMutableParagraphStyle()
            paragraph.lineSpacing = 3
            let attributes: [NSAttributedString.Key: Any] = [
                .font: UIFont(name: "Georgia", size: 10) ?? UIFont.systemFont(ofSize: 10),
                .foregroundColor: ink,
                .paragraphStyle: paragraph
            ]
            let attributed = NSAttributedString(string: text, attributes: attributes)
            let available = CGRect(x: 46, y: y, width: 520, height: 792 - y - 55)
            attributed.draw(in: available)

            let footer = "Skapad \(Date.now.formatted(date: .long, time: .omitted))  ·  Egna uppgifter och dokumenterade prisreferenser"
            (footer as NSString).draw(at: CGPoint(x: 46, y: 755), withAttributes: [
                .font: UIFont(name: "Georgia", size: 8) ?? UIFont.systemFont(ofSize: 8),
                .foregroundColor: UIColor.darkGray
            ])
        }
        try data.write(to: url, options: .atomic)
        return url
    }
}
