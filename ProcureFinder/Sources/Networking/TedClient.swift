import Foundation
import OSLog

// MARK: - Response-Modelle (defensiv)

private struct DynamicKey: CodingKey, Hashable {
    var stringValue: String
    var intValue: Int?
    init?(stringValue: String) { self.stringValue = stringValue }
    init?(intValue: Int) { self.intValue = intValue; self.stringValue = String(intValue) }
}

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
        let language: String?
        let ojsId: String?

        init(from decoder: Decoder) throws {
            let c = try decoder.container(keyedBy: DynamicKey.self)

            func decodeString(_ keys: [String]) -> String? {
                for k in keys {
                    if let dk = DynamicKey(stringValue: k) {
                        if let s = try? c.decodeIfPresent(String.self, forKey: dk), !s.isEmpty { return s }
                        if let i = try? c.decodeIfPresent(Int.self, forKey: dk) { return String(i) }
                        if let d = try? c.decodeIfPresent(Double.self, forKey: dk) { return String(d) }
                    }
                }
                return nil
            }
            func decodeDouble(_ keys: [String]) -> Double? {
                for k in keys {
                    if let dk = DynamicKey(stringValue: k) {
                        if let d = try? c.decodeIfPresent(Double.self, forKey: dk) { return d }
                        if let s = (try? c.decodeIfPresent(String.self, forKey: dk))?.trimmingCharacters(in: .whitespacesAndNewlines) {
                            if let d = Double(s) { return d }
                            let s2 = s.replacingOccurrences(of: ",", with: ".")
                            if let d = Double(s2) { return d }
                        }
                    }
                }
                return nil
            }
            func decodeDate(_ keys: [String]) -> Date? {
                let fmts = [
                    "yyyy-MM-dd'T'HH:mm:ssXXXXX",
                    "yyyy-MM-dd'T'HH:mm:ss.SSSXXXXX",
                    "yyyy-MM-dd"
                ].map { fmt -> DateFormatter in
                    let df = DateFormatter()
                    df.locale = Locale(identifier: "en_US_POSIX")
                    df.dateFormat = fmt
                    return df
                }
                if let s = decodeString(keys) {
                    for df in fmts { if let d = df.date(from: s) { return d } }
                }
                return nil
            }

            self.publicationNumber = decodeString(["ND","publication-number","ojs_number","publicationNumber"])
            self.title             = decodeString(["TI","title","title_en","title_de","title_fr"])
            self.country           = decodeString(["CY","country","country_code"])
            self.procedureType     = decodeString(["PT","procedure-type","procedureType"])
            self.cpvTopCode        = decodeString(["CPV","cpv","cpv_top","cpvTopCode"])
            self.budget            = decodeDouble(["VAL","BT-5381","estimatedValue","budget"])
            self.datePublished     = decodeDate(["PD","publication-date","datePublished"])
            self.language          = decodeString(["LG","language","lang"])
            self.ojsId             = decodeString(["ID","noticeId","ojs_id"])
        }
    }
}

// MARK: - Domain Mapping (DTO -> Notice)

extension TedSearchResponse.NoticeDTO {
    func toDomainNotice() -> Notice {
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
    private let endpoints = TedEndpoints()
    private let log = Logger(subsystem: "ProcureFinder", category: "TedClient")

    init(session: URLSession = .shared) {
        self.session = session
    }

    // Rohantwort
    func search(filters: SearchFilters, page: Int, pageSize: Int = 20) async throws -> TedSearchResponse {
        let req = try buildRequest(filters: filters, page: page, size: pageSize)
        log.debug("POST \(req.url?.absoluteString ?? "-") page=\(page, privacy: .public) size=\(pageSize, privacy: .public)")
        let (data, resp) = try await session.data(for: req)
        try Self.checkHTTP(resp)

        let dec = JSONDecoder()
        dec.dateDecodingStrategy = .iso8601
        do {
            let r = try dec.decode(TedSearchResponse.self, from: data)
            return r
        } catch {
            log.error("Decoding failed: \(error.localizedDescription, privacy: .public)")
            throw error
        }
    }

    // Direkt Domain-Modelle
    func searchNotices(filters: SearchFilters, page: Int, pageSize: Int = 20) async throws -> [Notice] {
        let r = try await search(filters: filters, page: page, pageSize: pageSize)
        return r.items.map { $0.toDomainNotice() }
    }

    // MARK: - Request Builder

    private func buildRequest(filters: SearchFilters, page: Int, size: Int) throws -> URLRequest {
        var urlRequest = URLRequest(url: endpoints.search)
        urlRequest.httpMethod = "POST"
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        urlRequest.timeoutInterval = 30

        var body: [String: Any] = [
            "page": max(0, page),
            "size": max(1, size),
            "sort": filters.sort.rawValue // sort ist nicht-optional
        ]

        // text ist nicht-optional
        let q = filters.text.trimmingCharacters(in: .whitespacesAndNewlines)
        if !q.isEmpty { body["query"] = q }

        if !filters.countries.isEmpty {
            body["countries"] = filters.countries
        }
        if !filters.procedures.isEmpty {
            body["procedureTypes"] = filters.procedures
        }
        if !filters.cpvCodes.isEmpty {
            body["cpv"] = filters.cpvCodes
        }
        if let from = filters.dateFrom {
            body["dateFrom"] = isoDate(from)
        }
        if let to = filters.dateTo {
            body["dateTo"] = isoDate(to)
        }

        urlRequest.httpBody = try JSONSerialization.data(withJSONObject: body, options: [])
        return urlRequest
    }

    private func isoDate(_ d: Date) -> String {
        let df = ISO8601DateFormatter()
        df.formatOptions = [.withFullDate]
        return df.string(from: d)
    }

    private static func checkHTTP(_ response: URLResponse) throws {
        guard let http = response as? HTTPURLResponse else { return }
        guard (200..<300).contains(http.statusCode) else {
            throw URLError(.badServerResponse)
        }
    }
}
