import Foundation

enum APIError: LocalizedError {
    case http(Int)
    var errorDescription: String? {
        switch self { case .http(let c): return "The budget service answered \(c). Try again." }
    }
}

/// Read-only client for the public BetterGov.ph Budget API.
struct BudgetAPI {
    static let shared = BudgetAPI()
    let base = URL(string: "https://budget.bettergov.ph")!
    private let root = "/api/v1/hgab/2027"
    private let session: URLSession = {
        let c = URLSessionConfiguration.default
        c.timeoutIntervalForRequest = 30
        c.requestCachePolicy = .reloadRevalidatingCacheData
        return URLSession(configuration: c)
    }()

    private func get<T: Decodable>(_ path: String, _ query: [URLQueryItem] = [], as: T.Type = T.self) async throws -> T {
        var comps = URLComponents(url: base, resolvingAgainstBaseURL: false)!
        comps.percentEncodedPath = path
        if !query.isEmpty { comps.queryItems = query }
        let (data, resp) = try await session.data(from: comps.url!)
        if let h = resp as? HTTPURLResponse, !(200..<300).contains(h.statusCode) { throw APIError.http(h.statusCode) }
        return try JSONDecoder().decode(T.self, from: data)
    }

    func overview() async throws -> Envelope<Overview> { try await get(root) }

    func regions() async throws -> Envelope<RegionsPage> { try await get("\(root)/datasets/dpwh/regions") }

    func projects(dataset: String = "dpwh", region: String? = nil, office: String? = nil, group: String? = nil,
                  q: String = "", offset: Int = 0, limit: Int = 50) async throws -> ProjectPage {
        var items = [URLQueryItem(name: "limit", value: String(limit)), URLQueryItem(name: "offset", value: String(offset))]
        if let region { items.append(.init(name: "region", value: region)) }
        if let office { items.append(.init(name: "office", value: office)) }
        if let group { items.append(.init(name: "group", value: group)) }
        if !q.isEmpty { items.append(.init(name: "q", value: q)) }
        return try await get("\(root)/datasets/\(dataset)/projects", items, as: Envelope<ProjectPage>.self).data
    }

    func districts(q: String) async throws -> [District] {
        let items = q.isEmpty ? [URLQueryItem(name: "limit", value: "300")] : [URLQueryItem(name: "q", value: q)]
        return try await get("\(root)/districts", items, as: Envelope<DistrictsPage>.self).data.districts
    }

    func district(id: String) async throws -> District {
        let enc = id.addingPercentEncoding(withAllowedCharacters: .alphanumerics) ?? id
        return try await get("\(root)/districts/\(enc)", [], as: Envelope<District>.self).data
    }

    func gaaTotals() async throws -> [GaaYear] { try await get("/api/v1/gaa", [], as: ListEnvelope<GaaYear>.self).data }
    func gaaDepartments() async throws -> [GaaDepartment] { try await get("/api/v1/gaa/departments", [], as: ListEnvelope<GaaDepartment>.self).data }
}
