import SwiftUI
import PhotosUI
import UIKit

struct AntiqueDetailView: View {
    @EnvironmentObject private var collection: CollectionStore
    @Environment(\.dismiss) private var dismiss
    @State private var item: SavedAntique
    @State private var selectedImages: [PhotosPickerItem] = []
    @State private var showingEvidenceForm = false
    @State private var showingDeleteConfirmation = false
    @State private var message: String?

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

                    if let message {
                        Text(message)
                            .font(.system(size: 13, design: .serif))
                            .foregroundStyle(AntiqueTheme.forest)
                    }

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
                .padding(.horizontal, 20)
                .padding(.top, 18)
            }
        }
        .navigationTitle("Föremål")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
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
        .onChange(of: selectedImages) { _, newItems in
            Task {
                for photo in newItems {
                    guard let data = try? await photo.loadTransferable(type: Data.self),
                          let image = UIImage(data: data) else { continue }
                    do {
                        try collection.addImage(image, to: item.id)
                        if let refreshed = collection.items.first(where: { $0.id == item.id }) {
                            item = refreshed
                        }
                    } catch {
                        message = error.localizedDescription
                    }
                }
                selectedImages = []
            }
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
                    .contextMenu {
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

    @State private var sourceName = ""
    @State private var amount = ""
    @State private var kind: SavedPriceEvidence.EvidenceKind = .realizedSale
    @State private var url = ""
    @State private var notes = ""
    @State private var evidenceDate = Date()

    var body: some View {
        NavigationStack {
            ZStack {
                PaperBackground()
                ScrollView {
                    VStack(alignment: .leading, spacing: 14) {
                        Text("Lägg till prisreferens")
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
                    Button("Lägg till") {
                        onAdd(SavedPriceEvidence(sourceName: sourceName.trimmingCharacters(in: .whitespacesAndNewlines),
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
