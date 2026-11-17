import SwiftUI
import PhotosUI
import UIKit

struct AntiqueDetailView: View {
    @EnvironmentObject private var collection: CollectionStore
    @Environment(\.dismiss) private var dismiss
    @State private var item: SavedAntique
    @State private var selectedImages: [PhotosPickerItem] = []
    @State private var imageImportGeneration = UUID()
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

                    inspectionOverview

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
        .sheet(isPresented: Binding(
            get: { exportedPDF != nil },
            set: { if !$0 { exportedPDF = nil } }
        )) {
            if let url = exportedPDF {
                ActivityShareSheet(activityItems: [url])
                    .presentationDetents([.medium, .large])
            }
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
            let generation = UUID()
            imageImportGeneration = generation
            Task {
                await importSelectedImages(newItems, generation: generation)
            }
        }
    }

    @MainActor
    private func importSelectedImages(_ photos: [PhotosPickerItem], generation: UUID) async {
        for photo in photos {
            guard generation == imageImportGeneration else { return }
            guard let data = try? await photo.loadTransferable(type: Data.self),
                  generation == imageImportGeneration,
                  let image = UIImage(data: data) else { continue }
            do {
                try collection.addImage(image, to: item.id)
                refreshItemFromCollection()
            } catch {
                message = error.localizedDescription
            }
        }
        // An older import must not clear a newer selection in the picker.
        if generation == imageImportGeneration {
            selectedImages = []
        }
    }

    private func refreshItemFromCollection() {
        let currentID = item.id
        if let refreshedItem = collection.items.first(where: { candidate in
            candidate.id == currentID
        }) {
            item = refreshedItem
        }
    }

    private var inspectionOverview: some View {
        let checks: [(String, Bool)] = [
            ("Föremålets namn", !item.title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && item.title != "Oidentifierat föremål"),
            ("Tillverkare", !item.maker.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty),
            ("Tidsperiod", !item.estimatedPeriod.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty),
            ("Material", !item.materials.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty),
            ("Märkningar", !item.markings.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty),
            ("Skick", !item.conditionNotes.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty),
            ("Proveniens", !item.provenance.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
        ]
        let completed = checks.filter(\.1).count

        return VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .firstTextBaseline) {
                Text("UNDERSÖKNINGENS STATUS")
                    .font(.system(size: 10, weight: .semibold, design: .serif))
                    .tracking(1.2)
                    .foregroundStyle(AntiqueTheme.brass)
                Spacer()
                Text("\(completed) av \(checks.count)")
                    .font(.system(size: 12, weight: .medium, design: .serif).monospacedDigit())
                    .foregroundStyle(AntiqueTheme.forest)
            }
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    Capsule().fill(AntiqueTheme.brass.opacity(0.2))
                    Capsule()
                        .fill(AntiqueTheme.forest)
                        .frame(width: geometry.size.width * CGFloat(completed) / CGFloat(checks.count))
                }
            }
            .frame(height: 5)

            Text(completed == checks.count
                 ? "Grunduppgifterna är dokumenterade. Kontrollera fortfarande uppgifterna mot föremålet och tillförlitliga källor."
                 : "Komplettera gärna de uppgifter som saknas. Lämna hellre ett fält tomt än att ange något du inte vet.")
                .font(.system(size: 12, design: .serif))
                .foregroundStyle(AntiqueTheme.mutedInk)

            HStack(alignment: .top, spacing: 6) {
                Image(systemName: "checkmark.circle")
                    .foregroundStyle(AntiqueTheme.forest)
                Text(checks.filter(\.1).map(\.0).joined(separator: " · ").isEmpty
                     ? "Inga uppgifter dokumenterade ännu"
                     : "Dokumenterat: " + checks.filter(\.1).map(\.0).joined(separator: " · "))
                    .foregroundStyle(AntiqueTheme.ink)
            }
            .font(.system(size: 11, design: .serif))
        }
        .padding(14)
        .background(AntiqueTheme.parchment)
        .overlay(RoundedRectangle(cornerRadius: 5).stroke(AntiqueTheme.brass.opacity(0.55), lineWidth: 1))
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
                        if !amount.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && !hasValidAmount {
                            Text("Ange ett positivt belopp, exempelvis 1250 eller 1250,50.")
                                .font(.system(size: 11, design: .serif))
                                .foregroundStyle(.red)
                        }

                        VStack(alignment: .leading, spacing: 5) {
                            Text("Typ av prisuppgift")
                                .font(.system(size: 12, weight: .medium, design: .serif))
                                .foregroundStyle(AntiqueTheme.walnut)
                            Picker("Typ", selection: $kind) {
                                ForEach(availableEvidenceKinds) { value in
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
                    .disabled(sourceName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || !hasValidAmount)
                    .foregroundStyle(AntiqueTheme.forest)
                }
            }
        }
    }

    // Accept Swedish decimal commas and common thousands separators, but reject
    // empty, malformed, zero and negative amounts before saving a price reference.
    private var normalizedAmount: String {
        var value = amount
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: " ", with: "")
            .replacingOccurrences(of: "\\u{00a0}", with: "")
            .replacingOccurrences(of: "\\u{202f}", with: "")
        if value.contains(",") {
            value = value.replacingOccurrences(of: ".", with: "")
                .replacingOccurrences(of: ",", with: ".")
        }
        return value
    }

    private var hasValidAmount: Bool {
        guard let value = Decimal(string: normalizedAmount, locale: Locale(identifier: "en_US_POSIX")) else {
            return false
        }
        return value > 0
    }

    // Keep legacy/unknown values visible while editing. Otherwise SwiftUI's
    // Picker has no matching tag and may silently display a misleading selection.
    private var availableEvidenceKinds: [SavedPriceEvidence.EvidenceKind] {
        var values = SavedPriceEvidence.EvidenceKind.allCases
        if case .unknown = kind {
            values.insert(kind, at: 0)
        }
        return values
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
        let safeTitle = item.title
            .replacingOccurrences(of: "/", with: "-")
            .replacingOccurrences(of: "\\", with: "-")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        let uniqueSuffix = UUID().uuidString.prefix(8)
        let filename = "Antikspanaren-\(safeTitle.isEmpty ? "Föremål" : safeTitle)-\(uniqueSuffix).pdf"
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(filename)
        let ink = UIColor(red: 0.12, green: 0.16, blue: 0.13, alpha: 1)
        let green = UIColor(red: 0.055, green: 0.145, blue: 0.105, alpha: 1)
        let brass = UIColor(red: 0.76, green: 0.59, blue: 0.30, alpha: 1)
        let paper = UIColor(red: 0.96, green: 0.93, blue: 0.86, alpha: 1)

        var sections: [(String, String)] = [
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
        ]
        for evidence in item.evidence {
            let date = evidence.date.map { $0.formatted(date: .numeric, time: .omitted) } ?? "Datum saknas"
            let details = [evidence.sourceName, evidence.amount + " kr", date, evidence.url, evidence.notes]
                .filter { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
                .joined(separator: "\n")
            sections.append((evidence.kind.title.uppercased(), details))
        }
        sections = sections.filter { !$0.1.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }

        let labelAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont(name: "Georgia-Bold", size: 9) ?? UIFont.boldSystemFont(ofSize: 9),
            .foregroundColor: green,
            .kern: 0.7
        ]
        let bodyParagraph = NSMutableParagraphStyle()
        bodyParagraph.lineSpacing = 3
        let bodyAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont(name: "Georgia", size: 10) ?? UIFont.systemFont(ofSize: 10),
            .foregroundColor: ink,
            .paragraphStyle: bodyParagraph
        ]

        let data = renderer.pdfData { context in
            var pageNumber = 0
            var y: CGFloat = 70
            let bottomLimit: CGFloat = 720

            func beginPage(first: Bool) {
                context.beginPage()
                pageNumber += 1
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

                if first {
                    var titleY: CGFloat = 70
                    if let coverImage {
                        let imageRect = CGRect(x: 46, y: titleY, width: 135, height: 125)
                        let ratio = min(imageRect.width / max(coverImage.size.width, 1), imageRect.height / max(coverImage.size.height, 1))
                        let size = CGSize(width: coverImage.size.width * ratio, height: coverImage.size.height * ratio)
                        coverImage.draw(in: CGRect(x: imageRect.midX - size.width / 2, y: imageRect.midY - size.height / 2, width: size.width, height: size.height))
                        titleY += 137
                    }
                    (item.title as NSString).draw(in: CGRect(x: 46, y: titleY, width: 520, height: 48), withAttributes: [
                        .font: UIFont(name: "Georgia", size: 24) ?? UIFont.systemFont(ofSize: 24),
                        .foregroundColor: green
                    ])
                    y = titleY + 58
                } else {
                    (item.title as NSString).draw(in: CGRect(x: 46, y: 68, width: 520, height: 25), withAttributes: [
                        .font: UIFont(name: "Georgia", size: 15) ?? UIFont.systemFont(ofSize: 15),
                        .foregroundColor: green
                    ])
                    y = 108
                }

                let footer = "Skapad \(Date.now.formatted(date: .long, time: .omitted))  ·  Sida \(pageNumber)"
                (footer as NSString).draw(at: CGPoint(x: 46, y: 755), withAttributes: [
                    .font: UIFont(name: "Georgia", size: 8) ?? UIFont.systemFont(ofSize: 8),
                    .foregroundColor: UIColor.darkGray
                ])
            }

            func beginContinuationPage(for heading: String) {
                beginPage(first: false)
                let continuation = heading + "  ·  FORTS."
                (continuation as NSString).draw(
                    in: CGRect(x: 46, y: y, width: 520, height: 14),
                    withAttributes: labelAttributes
                )
                y += 18
            }

            beginPage(first: true)

            for (heading, value) in sections {
                let labelSize = (heading as NSString).boundingRect(
                    with: CGSize(width: 520, height: CGFloat.greatestFiniteMagnitude),
                    options: [.usesLineFragmentOrigin, .usesFontLeading],
                    attributes: labelAttributes,
                    context: nil
                ).height
                let valueSize = (value as NSString).boundingRect(
                    with: CGSize(width: 520, height: CGFloat.greatestFiniteMagnitude),
                    options: [.usesLineFragmentOrigin, .usesFontLeading],
                    attributes: bodyAttributes,
                    context: nil
                ).height
                let sectionHeight = labelSize + 4 + valueSize + 13

                if y + min(sectionHeight, 90) > bottomLimit {
                    beginPage(first: false)
                }

                (heading as NSString).draw(in: CGRect(x: 46, y: y, width: 520, height: labelSize + 2), withAttributes: labelAttributes)
                y += labelSize + 4

                var remaining = value as NSString
                while remaining.length > 0 {
                    let availableHeight = bottomLimit - y
                    if availableHeight < 28 {
                        beginContinuationPage(for: heading)
                        continue
                    }

                    let fullSize = remaining.boundingRect(
                        with: CGSize(width: 520, height: CGFloat.greatestFiniteMagnitude),
                        options: [.usesLineFragmentOrigin, .usesFontLeading],
                        attributes: bodyAttributes,
                        context: nil
                    )
                    if fullSize.height <= availableHeight {
                        remaining.draw(in: CGRect(x: 46, y: y, width: 520, height: availableHeight), withAttributes: bodyAttributes)
                        y += fullSize.height + 13
                        remaining = ""
                    } else {
                        var low = 1
                        var high = remaining.length
                        var best = 0
                        while low <= high {
                            let mid = (low + high) / 2
                            let candidate = remaining.substring(to: mid) as NSString
                            let size = candidate.boundingRect(
                                with: CGSize(width: 520, height: CGFloat.greatestFiniteMagnitude),
                                options: [.usesLineFragmentOrigin, .usesFontLeading],
                                attributes: bodyAttributes,
                                context: nil
                            )
                            if size.height <= availableHeight - 8 {
                                best = mid
                                low = mid + 1
                            } else {
                                high = mid - 1
                            }
                        }
                        if best == 0 {
                            beginContinuationPage(for: heading)
                            continue
                        }
                        if best < remaining.length {
                            let split = (remaining.substring(to: best) as NSString).rangeOfCharacter(from: .whitespacesAndNewlines, options: .backwards)
                            if split.location != NSNotFound && split.location > best / 2 {
                                best = split.location + split.length
                            }
                        }
                        let chunk = remaining.substring(to: best) as NSString
                        let chunkSize = chunk.boundingRect(
                            with: CGSize(width: 520, height: CGFloat.greatestFiniteMagnitude),
                            options: [.usesLineFragmentOrigin, .usesFontLeading],
                            attributes: bodyAttributes,
                            context: nil
                        )
                        chunk.draw(in: CGRect(x: 46, y: y, width: 520, height: availableHeight), withAttributes: bodyAttributes)
                        y += chunkSize.height + 5
                        remaining = remaining.substring(from: best) as NSString
                        beginContinuationPage(for: heading)
                    }
                }
            }
        }

        try data.write(to: url, options: Data.WritingOptions.atomic)
        return url
    }
}
