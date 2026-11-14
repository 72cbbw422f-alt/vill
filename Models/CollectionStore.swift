import Foundation
import SwiftUI
import UIKit

struct SavedPriceEvidence: Identifiable, Codable {
    var id: UUID = UUID()
    var sourceName: String
    var amount: String
    var kind: EvidenceKind
    var date: Date?
    var url: String
    var notes: String

    enum EvidenceKind: String, Codable, CaseIterable, Identifiable {
        case realizedSale
        case askingPrice
        case auctionEstimate
        case expertOpinion

        var id: String { rawValue }
        var title: String {
            switch self {
            case .realizedSale: return "Klubbat slutpris"
            case .askingPrice: return "Begärt pris"
            case .auctionEstimate: return "Auktionsvärdering"
            case .expertOpinion: return "Expertbedömning"
            }
        }
    }
}

struct SavedAntique: Identifiable, Codable {
    var id: UUID = UUID()
    var title: String
    var maker: String
    var notes: String
    var purchasePrice: String
    var imageFileName: String
    var createdAt: Date = .now
    var additionalImageFileNames: [String] = []
    var estimatedPeriod: String = ""
    var materials: String = ""
    var markings: String = ""
    var provenance: String = ""
    var conditionNotes: String = ""
    var valuationLow: String = ""
    var valuationHigh: String = ""
    var valuationNotes: String = ""
    var evidence: [SavedPriceEvidence] = []

    var allImageFileNames: [String] { [imageFileName] + additionalImageFileNames }

    private enum CodingKeys: String, CodingKey {
        case id, title, maker, notes, purchasePrice, imageFileName, createdAt
        case additionalImageFileNames, estimatedPeriod, materials, markings, provenance
        case conditionNotes, valuationLow, valuationHigh, valuationNotes, evidence
    }

    init(id: UUID = UUID(), title: String, maker: String, notes: String, purchasePrice: String,
         imageFileName: String, createdAt: Date = .now, additionalImageFileNames: [String] = [],
         estimatedPeriod: String = "", materials: String = "", markings: String = "",
         provenance: String = "", conditionNotes: String = "", valuationLow: String = "",
         valuationHigh: String = "", valuationNotes: String = "", evidence: [SavedPriceEvidence] = []) {
        self.id = id
        self.title = title
        self.maker = maker
        self.notes = notes
        self.purchasePrice = purchasePrice
        self.imageFileName = imageFileName
        self.createdAt = createdAt
        self.additionalImageFileNames = additionalImageFileNames
        self.estimatedPeriod = estimatedPeriod
        self.materials = materials
        self.markings = markings
        self.provenance = provenance
        self.conditionNotes = conditionNotes
        self.valuationLow = valuationLow
        self.valuationHigh = valuationHigh
        self.valuationNotes = valuationNotes
        self.evidence = evidence
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decodeIfPresent(UUID.self, forKey: .id) ?? UUID()
        title = try c.decodeIfPresent(String.self, forKey: .title) ?? "Oidentifierat föremål"
        maker = try c.decodeIfPresent(String.self, forKey: .maker) ?? ""
        notes = try c.decodeIfPresent(String.self, forKey: .notes) ?? ""
        purchasePrice = try c.decodeIfPresent(String.self, forKey: .purchasePrice) ?? ""
        imageFileName = try c.decodeIfPresent(String.self, forKey: .imageFileName) ?? ""
        createdAt = try c.decodeIfPresent(Date.self, forKey: .createdAt) ?? .now
        additionalImageFileNames = try c.decodeIfPresent([String].self, forKey: .additionalImageFileNames) ?? []
        estimatedPeriod = try c.decodeIfPresent(String.self, forKey: .estimatedPeriod) ?? ""
        materials = try c.decodeIfPresent(String.self, forKey: .materials) ?? ""
        markings = try c.decodeIfPresent(String.self, forKey: .markings) ?? ""
        provenance = try c.decodeIfPresent(String.self, forKey: .provenance) ?? ""
        conditionNotes = try c.decodeIfPresent(String.self, forKey: .conditionNotes) ?? ""
        valuationLow = try c.decodeIfPresent(String.self, forKey: .valuationLow) ?? ""
        valuationHigh = try c.decodeIfPresent(String.self, forKey: .valuationHigh) ?? ""
        valuationNotes = try c.decodeIfPresent(String.self, forKey: .valuationNotes) ?? ""
        evidence = try c.decodeIfPresent([SavedPriceEvidence].self, forKey: .evidence) ?? []
    }
}

@MainActor
final class CollectionStore: ObservableObject {
    @Published private(set) var items: [SavedAntique] = []
    private let fileManager = FileManager.default

    init() { load() }

    func add(title: String, maker: String, notes: String, purchasePrice: String, image: UIImage) throws {
        guard let imageData = image.jpegData(compressionQuality: 0.88) else { throw StoreError.imageEncodingFailed }
        let folder = try imagesFolder()
        let filename = UUID().uuidString + ".jpg"
        let imageURL = folder.appendingPathComponent(filename)
        try imageData.write(to: imageURL, options: .atomic)

        let item = SavedAntique(
            title: title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? "Oidentifierat föremål" : title,
            maker: maker, notes: notes, purchasePrice: purchasePrice, imageFileName: filename
        )
        items.insert(item, at: 0)
        do { try persist() }
        catch {
            items.removeAll { $0.id == item.id }
            try? fileManager.removeItem(at: imageURL)
            throw error
        }
    }

    func update(_ updated: SavedAntique) throws {
        guard let index = items.firstIndex(where: { $0.id == updated.id }) else { return }
        let previous = items[index]
        items[index] = updated
        do { try persist() }
        catch { items[index] = previous; throw error }
    }

    func addImage(_ image: UIImage, to itemID: UUID) throws {
        guard let index = items.firstIndex(where: { $0.id == itemID }) else { return }
        guard let data = image.jpegData(compressionQuality: 0.88) else { throw StoreError.imageEncodingFailed }
        let filename = UUID().uuidString + ".jpg"
        let url = try imagesFolder().appendingPathComponent(filename)
        try data.write(to: url, options: .atomic)
        let previous = items[index]
        items[index].additionalImageFileNames.append(filename)
        do { try persist() }
        catch {
            items[index] = previous
            try? fileManager.removeItem(at: url)
            throw error
        }
    }

    func removeAdditionalImage(_ filename: String, from itemID: UUID) throws {
        guard let index = items.firstIndex(where: { $0.id == itemID }),
              items[index].additionalImageFileNames.contains(filename) else { return }
        let previous = items[index]
        items[index].additionalImageFileNames.removeAll { $0 == filename }
        do {
            try persist()
            try? fileManager.removeItem(at: imagesFolder().appendingPathComponent(filename))
        } catch {
            items[index] = previous
            throw error
        }
    }

    func delete(_ item: SavedAntique) throws {
        guard let index = items.firstIndex(where: { $0.id == item.id }) else { return }
        let removed = items.remove(at: index)
        do {
            try persist()
            for name in removed.allImageFileNames {
                try? fileManager.removeItem(at: imagesFolder().appendingPathComponent(name))
            }
        } catch {
            items.insert(removed, at: index)
            throw error
        }
    }

    func image(named filename: String) -> UIImage? {
        guard let folder = try? imagesFolder(),
              let data = try? Data(contentsOf: folder.appendingPathComponent(filename)) else { return nil }
        return UIImage(data: data)
    }

    func image(for item: SavedAntique) -> UIImage? { image(named: item.imageFileName) }

    private func load() {
        guard let url = try? dataFileURL(),
              let data = try? Data(contentsOf: url),
              let decoded = try? JSONDecoder().decode([SavedAntique].self, from: data) else {
            items = []
            return
        }
        items = decoded.sorted { $0.createdAt > $1.createdAt }
    }

    private func persist() throws {
        let data = try JSONEncoder().encode(items)
        try data.write(to: dataFileURL(), options: .atomic)
    }

    private func dataFileURL() throws -> URL {
        try fileManager.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
            .appendingPathComponent("antikspanaren-items.json")
    }

    private func imagesFolder() throws -> URL {
        let documents = try fileManager.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
        let folder = documents.appendingPathComponent("AntikspanarenImages", isDirectory: true)
        if !fileManager.fileExists(atPath: folder.path) {
            try fileManager.createDirectory(at: folder, withIntermediateDirectories: true)
        }
        return folder
    }

    enum StoreError: LocalizedError {
        case imageEncodingFailed
        var errorDescription: String? { "Bilden kunde inte sparas. Försök med en annan bild." }
    }
}
