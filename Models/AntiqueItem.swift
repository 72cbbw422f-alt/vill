import Foundation

struct AntiqueItem: Identifiable, Codable {
    var id: UUID = UUID()
    var title: String
    var description: String
    var maker: String?
    var estimatedPeriod: String?
    var materials: [String]
    var provenance: String?
    var imageFileName: String?
    var createdAt: Date = .now
}