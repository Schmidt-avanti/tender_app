import Foundation
import OSLog

// MARK: - Dynamic key for tolerant decoding
private struct DynamicKey: CodingKey, Hashable {
    var stringValue: String
    var intValue: Int?
    init?(stringValue: String) { self.stringValue = stringValue }
    init?(intValue: Int) { self.intValue = intValue; self.stringValue = String(intValue) }
}

// MARK: - Response models (defensive)
struct TedSearchResponse: Decodable {
    let total: Int
    let items: [NoticeDTO]

    init(total: Int = 0, items: [NoticeDTO] = []) {
        self.total = total
        self.items = items
    }

    private enum K: String, CodingKey { case total, totalCount, count, items, results, notices, data }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: K.self)
        let totalA = try c.decodeIfPresent(Int.self, forKey: .total)
        let totalB = try c.decodeIfPresent(Int.self, forKey: .totalCount)
        let totalC = try c.decodeIfPresent(Int.self, forKey: .count)
        self.total = totalA ?? totalB ?? totalC ?? 0

        if let arr = try c.decodeIfPresent([NoticeDTO].self, forKey: .items) { self.items = arr; return }
        if let arr = try c.decodeIfPresent([NoticeDTO].self, forKey: .results) { self.items = arr; return }
        if let arr = try c.decodeIfPresent([NoticeDTO].self, forKey: .notices) { self.items = arr; return }

        if let nested = try? c.nestedContainer(keyedBy: DynamicKey.self, forKey: .data),
           let key = DynamicKey(stringValue: "items"),
           let arr = try? nested.decodeIfPresent([NoticeDTO].self, forKey: key) {
            self.items = arr ?? []
            return
        }
        self.items = []
    }

    struct NoticeDTO: Decodable {
        let publicationNumber: String?
        let title: String?
        let country: String?
        let procedureType: String?
        let cpvTopCode: String?
        let budget: Double?
        let datePublished: Date?

        init(from decoder: Decoder) throws {
            let c = try decoder.container(keyedBy: DynamicKey.self)

            func s(_ keys: [String]) -> String? {
                for k in keys {
                    if let dk = DynamicKey(stringValue: k) {
                        if let v = try? c.decodeIfPresent(String.self, forKey: dk), !v.isEmpty { return v }
                        if let i = try? c.decodeIfPresent(Int.self, forKey: dk) { return String(i) }
                        if let d = try? c.decodeIfPresent(Double.self, forKey: dk) { return String(d) }
                    }
                }
                return nil
            }
            func d(_ keys: [String]) -> Double? {
                for k in keys {
                    if let dk = DynamicKey(stringValue: k) {
                        if let v = try? c.decodeIfPresent(Double.self, forKey: dk) { return v }
                        if let str = (try? c.decodeIfPresent(String.self, forKey: dk))?.trimmingCharacters(in: .whitespacesAndNewlines) {
                            if let v = Double(str) { return v }
                            let v2 = Double(str.replacingOccurrences(of: ",", with: "."))
                            if let v2 { return v2 }
                        }
                    }
                }
                return nil
            }
            func date(_ keys: [String]) -> Date? {
                let f = ["yyyy-MM-dd'T'HH:mm:ssXXXXX","yyyy-MM-dd'T'HH:mm:ss.SSSXXXXX","yyyy-MM-dd"].map {
                    let df = DateFormatter(); df.locale = Locale(identifier: "en_US_POSIX"); df.dateFormat = $0; return df
                }
                if let raw = s(keys) {
                    for df in f { if let v = df.date(from: raw) { return v } }
                }
                return nil
            }

            publicationNumber = s(["ND","publication-number","ojs_number","publicationNumber"])
            title             = s(["TI","title","title_en","title_de","title_fr"])
            country           = s(["CY","country","country_code"])
            procedureType     = s(["PT","procedure-type","procedureType"])
            cpvTopCode        = s(["CPV","cpv","cpv_top","cpvTopCode"])
            budget            = d(["VAL","BT-5381","estimatedValue","budget"])
            datePublished     = date(["PD","publication-date","datePublished"])
        }
    }
}

// MARK: - DTO -> Domain mapping
extension TedSearchResponse.NoticeDTO {
    func toDomain() -> Notice {
        let pub = publicationNumber ?? UUID().uuidString
        return Notice(
            publicationNumber: pub,
            title: title ?? "—",
            country: country ?? "—",
            procedure: procedureType ?? "—",
            cpvTop: cpvTopCode,
            budget: budget,
            publicationDate: datePublished
        )
    }
}

// MARK: - Client
final class TedClient {

    static let shared = TedClient()
    private let session: URLSession
    private let log = Logger(subsystem: "ProcureFinder", category: "TedClient")

    init(session: URLSession = .shared) {
        self.session = session
    }

    // Rohantwort
    func search(filters: SearchFilters, page: Int, pageSize: Int = 20) async throws -> TedSearchResponse {
        var req = URLRequest(url: TedEndpoints.search)
        req.httpMethod = "POST"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.timeoutInterval = 30

        var body: [String: Any] = [
            "page": max(0, page),
            "size": max(1, pageSize),
            "sort": filters.sort.rawValue
        ]

        let q = filters.text.trimmingCharacters(in: .whitespacesAndNewlines)
        if !q.isEmpty { body["query"] = q }
        if !filters.countries.isEmpty { body["countries"] = filters.countries }
        if !filters.procedures.isEmpty { body["procedureTypes"] = filters.procedures }
        if !filters.cpvCodes.isEmpty { body["cpv"] = filters.cpvCodes }
        if let from = filters.dateFrom { body["dateFrom"] = isoDate(from) }
        if let to = filters.dateTo { body["dateTo"] = isoDate(to) }

        req.httpBody = try JSONSerialization.data(withJSONObject: body, options: [])

        log.debug("POST \(req.url?.absoluteString ?? "-") page=\(page, privacy: .public) size=\(pageSize, privacy: .public)")
        let (data, resp) = try await session.data(for: req)
        try Self.check(resp)

        let dec = JSONDecoder(); dec.dateDecodingStrategy = .iso8601
        return try dec.decode(TedSearchResponse.self, from: data)
    }

    // Komfort: direkt Domain-Modelle
    func searchNotices(filters: SearchFilters, page: Int, pageSize: Int = 20) async throws -> [Notice] {
        let r = try await search(filters: filters, page: page, pageSize: pageSize)
        return r.items.map { $0.toDomain() }
    }

    // MARK: - Helpers
    private func isoDate(_ d: Date) -> String {
        let df = ISO8601DateFormatter(); df.formatOptions = [.withFullDate]; return df.string(from: d)
    }
    private static func check(_ response: URLResponse) throws {
        guard let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
            throw URLError(.badServerResponse)
        }
    }
}
