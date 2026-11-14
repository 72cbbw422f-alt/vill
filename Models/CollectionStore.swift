import Foundation
import SwiftUI
import UIKit

struct SavedAntique: Identifiable, Codable {
    var id: UUID = UUID()
    var title: String
    var maker: String
    var notes: String
    var purchasePrice: String
    var imageFileName: String
    var createdAt: Date = .now
}

@MainActor
final class CollectionStore: ObservableObject {
    @Published private(set) var items: [SavedAntique] = []

    private let fileManager = FileManager.default

    init() {
        load()
    }

    func add(title: String, maker: String, notes: String, purchasePrice: String, image: UIImage) throws {
        guard let imageData = image.jpegData(compressionQuality: 0.88) else {
            throw StoreError.imageEncodingFailed
        }

        let folder = try imagesFolder()
        let filename = UUID().uuidString + ".jpg"
        let imageURL = folder.appendingPathComponent(filename)
        try imageData.write(to: imageURL, options: .atomic)

        let item = SavedAntique(
            title: title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? "Oidentifierat föremål" : title,
            maker: maker,
            notes: notes,
            purchasePrice: purchasePrice,
            imageFileName: filename
        )

        items.insert(item, at: 0)
        do {
            try persist()
        } catch {
            items.removeAll { $0.id == item.id }
            try? fileManager.removeItem(at: imageURL)
            throw error
        }
    }

    func image(for item: SavedAntique) -> UIImage? {
        guard let folder = try? imagesFolder() else { return nil }
        let url = folder.appendingPathComponent(item.imageFileName)
        guard let data = try? Data(contentsOf: url) else { return nil }
        return UIImage(data: data)
    }

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

        var errorDescription: String? {
            "Bilden kunde inte sparas. Försök med en annan bild."
        }
    }
}
