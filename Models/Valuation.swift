import Foundation

enum EvidenceType: String, Codable {
    case realizedSale
    case askingPrice
    case auctionEstimate
    case expertOpinion
}

struct ValuationEvidence: Identifiable, Codable {
    var id: UUID = UUID()
    var sourceName: String
    var sourceURL: URL?
    var evidenceType: EvidenceType
    var amount: Decimal
    var currencyCode: String = "SEK"
    var saleDate: Date?
    var notes: String?
}

struct ValuationAssessment: Codable {
    var lowEstimate: Decimal?
    var highEstimate: Decimal?
    var confidenceNote: String
    var evidence: [ValuationEvidence]
    var assessedAt: Date = .now
}