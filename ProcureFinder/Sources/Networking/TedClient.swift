import Foundation
import OSLog

/// Request for TED Search API. Uses expert query string and pagination.
struct TedSearchRequest: Encodable {
    let query: String
    let page: Int
    let limit: Int
    let sort: String? // e.g. "publication-date,desc"
    let fields: [String]? // optional list of fields
}

/// Minimal response structure (defensive decoding).
struct TedSearchResponse: Decodable {
    let total: Int?
    let count: Int?
    let page: Int?
    let results: [NoticeDTO]

    struct NoticeDTO: Decodable {
        let publicationNumber: String?
        let publicationDate: String?
        let title: String?
        let country: String?
        let procedure: String?
        let cpvTop: String?
        let budget: Double?
        let buyer: String?

        // Defensive decoding across possible keys
        init(from decoder: Decoder) throws {
            let c = try decoder.container(keyedBy: CodingKeys.self)
            publicationNumber = try c.decodeIfPresent(String.self, forKeys: ["publication-number","ND","publicationNumber"])
            publicationDate = try c.decodeIfPresent(String.self, forKeys: ["publication-date","PD","publicationDate"])
            title = try c.decodeIfPresent(String.self, forKeys: ["title","TI","notice-title"])
            country = try c.decodeIfPresent(String.self, forKeys: ["country","buyer-country","CY"])
            procedure = try c.decodeIfPresent(String.self, forKeys: ["procedure-type","PT","procedure"])
            cpvTop = try c.decodeIfPresent(String.self, forKeys: ["cpv","CPV","cpvTop"])
            budget = try c.decodeIfPresent(Double.self, forKeys: ["estimated-value","EV","budget"])
            buyer = try c.decodeIfPresent(String.self, forKeys: ["buyer","buyer-name"])
        }
        enum CodingKeys: String, CodingKey {
            case dummy
        }
    }
}

private extension KeyedDecodingContainer {
    func decodeIfPresent(_ type: String.Type, forKeys keys: [String]) throws -> String? {
        for k in keys {
            if let key = CodingKeyWrapper(stringValue: k), let v = try decodeIfPresent(String.self, forKey: key) { return v }
        }
        return nil
    }
    func decodeIfPresent(_ type: Double.Type, forKeys keys: [String]) throws -> Double? {
        for k in keys {
            if let key = CodingKeyWrapper(stringValue: k), let v = try decodeIfPresent(Double.self, forKey: key) { return v }
        }
        return nil
    }
    struct CodingKeyWrapper: CodingKey {
        var stringValue: String
        init?(stringValue: String) { self.stringValue = stringValue }
        var intValue: Int? { nil }
        init?(intValue: Int) { return nil }
    }
}

actor TedClient {
    static let shared = TedClient()
    private let session: URLSession
    private let log = Logger(subsystem: "ProcureFinder", category: "TedClient")
    private var etags: [URL:String] = [:]

    init(session: URLSession = .shared) {
        self.session = session
    }

    func search(request: TedSearchRequest) async throws -> TedSearchResponse {
        var req = URLRequest(url: TedEndpoints.search)
        req.httpMethod = "POST"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        let encoder = JSONEncoder()
        req.httpBody = try encoder.encode(request)

        do {
            let (data, response) = try await session.data(for: req)
            if let http = response as? HTTPURLResponse, !(200...299).contains(http.statusCode) {
                throw URLError(.badServerResponse)
            }
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            // Tolerate extra/missing fields
            let generic = try decoder.decode(GenericResponse.self, from: data)
            // Map into TedSearchResponse
            let results = generic.results?.map { item in
                TedSearchResponse.NoticeDTO(
                    publicationNumber: item["ND"] as? String ?? item["publication-number"] as? String,
                    publicationDate: item["PD"] as? String ?? item["publication-date"] as? String,
                    title: item["TI"] as? String ?? item["title"] as? String,
                    country: item["CY"] as? String ?? item["buyer-country"] as? String,
                    procedure: item["PT"] as? String ?? item["procedure-type"] as? String,
                    cpvTop: (item["CPV"] as? [String])?.first ?? item["cpv"] as? String,
                    budget: item["EV"] as? Double ?? (item["estimated-value"] as? Double),
                    buyer: item["buyer"] as? String ?? item["buyer-name"] as? String
                )
            } ?? []
            return TedSearchResponse(total: generic.total, count: generic.count, page: generic.page, results: results)
        } catch {
            log.error("Search error: \(error.localizedDescription)")
            throw error
        }
    }

    // Generic dynamic map response to be resilient to schema changes
    private struct GenericResponse: Decodable {
        let total: Int?
        let count: Int?
        let page: Int?
        let results: [[String: AnyDecodable]]?
        enum CodingKeys: String, CodingKey { case total, count, page, results }
        init(from decoder: Decoder) throws {
            let c = try decoder.container(keyedBy: CodingKeys.self)
            total = try c.decodeIfPresent(Int.self, forKey: .total)
            count = try c.decodeIfPresent(Int.self, forKey: .count)
            page = try c.decodeIfPresent(Int.self, forKey: .page)
            results = try c.decodeIfPresent([[String: AnyDecodable]].self, forKey: .results)
        }
    }
}

// Type-erased Decodable for dynamic maps
struct AnyDecodable: Decodable {
    let value: Any
    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let v = try? container.decode(String.self) { value = v; return }
        if let v = try? container.decode(Double.self) { value = v; return }
        if let v = try? container.decode(Int.self) { value = v; return }
        if let v = try? container.decode(Bool.self) { value = v; return }
        if let v = try? container.decode([String].self) { value = v; return }
        if let v = try? container.decode([String: AnyDecodable].self) { value = v; return }
        value = NSNull()
    }
}

extension Dictionary where Key == String, Value == AnyDecodable {
    subscript<T>(_ key: String) -> T? { self[key]?.value as? T }
}
