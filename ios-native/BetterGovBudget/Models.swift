import Foundation

struct Envelope<T: Decodable>: Decodable {
    let data: T
    let disclaimers: [Disclaimer]?
}

struct Disclaimer: Decodable, Identifiable {
    let id: String
    let title: String
    let body: String
}

struct Overview: Decodable {
    let title: String
    let summary: String
    let datasets: [Dataset]
}

struct Dataset: Decodable, Identifiable, Hashable {
    static func == (a: Dataset, b: Dataset) -> Bool { a.key == b.key }
    func hash(into h: inout Hasher) { h.combine(key) }
    var id: String { key }
    let key: String
    let label: String
    let short: String?
    let summary: String?
    let bridge: Bridge?
}

struct Bridge: Decodable {
    let groups: [String: Group]
    let note: String?
    struct Group: Decodable {
        let label: String
        let sub: String?
        let help: String?
        let rows: Int
        let php: Double?
    }
    /// Stable display order.
    static let order = ["house_only", "nep_only", "increased", "decreased", "unchanged", "scope_review"]
}

struct RegionsPage: Decodable {
    let regions: [Region]
    let note: String?
}

struct Region: Decodable, Identifiable, Hashable {
    var id: String { key }
    let key: String
    let name: String
    let label: String?
    let nepPhp: Double?
    let housePhp: Double?
    let deltaPhp: Double?
    let nepRows: Int?
    let houseRows: Int?
    enum CodingKeys: String, CodingKey {
        case key, name, label
        case nepPhp = "nep_php", housePhp = "house_php", deltaPhp = "delta_php"
        case nepRows = "nep_rows", houseRows = "house_rows"
    }
}

struct ProjectPage: Decodable {
    let total: Int
    let rows: [ProjectRow]
}

struct ProjectRow: Decodable, Identifiable, Hashable {
    let id: String
    let dataset: String?
    let title: String
    let program: String?
    let pap: String?
    let region: String?
    let office: String?
    let statusLabel: String?
    let bridgeGroup: String?
    let groupLabel: String?
    let nepPhp: Double?
    let housePhp: Double?
    let deltaPhp: Double?
    let nepPage: Int?
    let hgab3Page: Int?
    let pdfUrl: PdfUrls?
    let url: String?
    struct PdfUrls: Decodable, Hashable {
        let nep: String?
        let hgab3: String?
        let hgab2: String?
    }
    enum CodingKeys: String, CodingKey {
        case id, dataset, title, program, pap, region, office, url
        case statusLabel = "status_label", bridgeGroup = "bridge_group", groupLabel = "group_label"
        case nepPhp = "nep_php", housePhp = "house_php", deltaPhp = "delta_php"
        case nepPage = "nep_page", hgab3Page = "hgab3_page", pdfUrl = "pdf_url"
    }
}

struct DistrictsPage: Decodable {
    let total: Int
    let districts: [District]
}

struct District: Decodable, Identifiable, Hashable {
    static func == (a: District, b: District) -> Bool { a.id == b.id }
    func hash(into h: inout Hasher) { h.combine(id) }
    let id: String
    let label: String
    let jurisdiction: String?
    let region: String?
    let representative: Rep?
    let offices: [Office]?
    let headline: Headline?
    struct Rep: Decodable {
        let name: String?
        let profileUrl: String?
        enum CodingKeys: String, CodingKey { case name, profileUrl = "profile_url" }
    }
    struct Office: Decodable, Identifiable {
        let id: String
        let name: String
        let tier: String?
        let tierText: String?
        let years: [Year]?
        struct Year: Decodable { let matchedLabel: String?
            enum CodingKeys: String, CodingKey { case matchedLabel = "matched_label" } }
        /// The ledger name the projects API filters on.
        var ledgerName: String { years?.compactMap(\.matchedLabel).first ?? name }
        enum CodingKeys: String, CodingKey { case id, name, tier, years, tierText = "tier_text" }
    }
    struct Headline: Decodable {
        let fy2026: Double?
        let nep: Double?
        let house: Double?
        let note: String?
        enum CodingKeys: String, CodingKey {
            case fy2026 = "fy2026_gaa_php", nep = "fy2027_nep_php", house = "fy2027_hgab3_php", note
        }
    }
}

struct GaaYear: Decodable, Identifiable {
    var id: Int { year }
    let year: Int
    let lineItems: Int
    let amount: Double
    enum CodingKeys: String, CodingKey { case year, amount, lineItems = "line_items" }
}

struct GaaDepartment: Decodable, Identifiable {
    let id: String
    let description: String
    let years: [String: YearAmount]
    struct YearAmount: Decodable { let count: Int; let amount: Double }
    func amount(_ year: Int) -> Double { years[String(year)]?.amount ?? 0 }
}

struct ListEnvelope<T: Decodable>: Decodable { let data: [T] }
