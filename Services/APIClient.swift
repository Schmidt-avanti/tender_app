import Foundation
import Combine

// ---------- Dynamische Decodierung ----------
private struct TedSearchResponseDynamic: Decodable {
    let total: Int?
    let notices: [[String: AnyDecodable]]?

    enum CodingKeys: String, CodingKey { case total, notices }
}

private struct AnyDecodable: Decodable {
    let value: Any
    init(from decoder: Decoder) throws {
        let c = try decoder.singleValueContainer()
        if let v = try? c.decode(String.self)  { value = v; return }
        if let v = try? c.decode(Int.self)     { value = v; return }
        if let v = try? c.decode(Double.self)  { value = v; return }
        if let v = try? c.decode(Bool.self)    { value = v; return }
        if let v = try? c.decode([String: AnyDecodable].self) {
            value = v.mapValues { $0.value }; return
        }
        if let v = try? c.decode([AnyDecodable].self) {
            value = v.map { $0.value }; return
        }
        value = NSNull()
    }
}

// ---------- Hilfen ----------
private enum DateParser {
    static let iso = ISO8601DateFormatter()
    static let ymd: DateFormatter = {
        let df = DateFormatter()
        df.calendar = Calendar(identifier: .iso8601)
        df.locale = Locale(identifier: "en_US_POSIX")
        df.dateFormat = "yyyy-MM-dd"
        return df
    }()

    static func parse(_ s: String?) -> Date? {
        guard let s else { return nil }
        // erst ISO, dann yyyy-MM-dd
        if let d = iso.date(from: s) { return d }
        if let d = ymd.date(from: s) { return d }
        return nil
    }
}

// ---------- API-Client ----------
final class APIClient {
    static let shared = APIClient()
    private init() {}

    /// Start-Fields (klein aber nützlich). Server kann andere verlangen;
    /// dann lesen wir die „supported values“ aus der Fehlermeldung und retryen.
    private let preferredFields: [String] = [
        "notice-title",              // Titel
        "publication-date",          // Veröffentlichungsdatum
        "buyer-country",             // Land
        "submission-url-lot",        // Deeplink (falls vorhanden)

        // mehrere mögliche Deadline-Felder (Gateways unterscheiden sich)
        "submission-deadline-lot",
        "time-limit-receipt-tenders-lot",
        "deadline-receipt-tenders-lot"
    ]

    func search(filters: SearchFilters) -> AnyPublisher<[Tender], Error> {
        let q = buildExpertQuery(from: filters)

        return performSearch(query: q, fields: preferredFields)
            .catch { [weak self] error -> AnyPublisher<[Tender], Error> in
                guard let self else { return Fail(error: error).eraseToAnyPublisher() }

                // Ungültige Fields? -> unterstützte Liste parsen & minimal gültiges Set wählen
                if let supported = self.extractSupportedFields(from: error), !supported.isEmpty {
                    let minimal = self.pickMinimalFieldSet(from: supported)
                    return self.performSearch(query: q, fields: minimal)
                }

                // Query-Problem (Syntax/Unknown field)? -> pure Volltextsuche als Fallback
                if self.isQuerySyntaxError(error) || self.isUnknownFieldError(error) {
                    let fallbackQ = #"FT~(tender)"#
                    return self.performSearch(query: fallbackQ, fields: self.preferredFields)
                }
                return Fail(error: error).eraseToAnyPublisher()
            }
            .eraseToAnyPublisher()
    }

    // ---------- Request/Response ----------
    private func performSearch(query: String, fields: [String]) -> AnyPublisher<[Tender], Error> {
        guard let url = URL(string: "https://api.ted.europa.eu/v3/notices/search") else {
            return Fail(error: URLError(.badURL)).eraseToAnyPublisher()
        }
        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.setValue("application/json", forHTTPHeaderField: "Accept")
        req.setValue("TendersApp/1.0 (iOS)", forHTTPHeaderField: "User-Agent")

        let body: [String: Any] = [
            "query": query,
            "page": 1,
            "limit": 25,
            "fields": fields
        ]

        do { req.httpBody = try JSONSerialization.data(withJSONObject: body) }
        catch { return Fail(error: error).eraseToAnyPublisher() }

        let decoder = JSONDecoder()

        return URLSession.shared.dataTaskPublisher(for: req)
            .tryMap { out in
                guard let http = out.response as? HTTPURLResponse else {
                    throw URLError(.badServerResponse)
                }
                guard (200..<300).contains(http.statusCode) else {
                    let msg = String(data: out.data, encoding: .utf8) ?? "HTTP \(http.statusCode)"
                    throw NSError(domain: "TEDSearch", code: http.statusCode,
                                  userInfo: [NSLocalizedDescriptionKey: msg])
                }
                return out.data
            }
            .decode(type: TedSearchResponseDynamic.self, decoder: decoder)
            .map { [weak self] resp in
                let rows = resp.notices ?? []
                return rows.compactMap { self?.mapDynamicNotice($0) }
            }
            .receive(on: RunLoop.main)
            .eraseToAnyPublisher()
    }

    // ---------- Mapping ----------
    private func mapDynamicNotice(_ dict: [String: AnyDecodable]) -> Tender {
        let country = (dict["buyer-country"]?.value as? String)

        // Titel
        let title =
            (dict["notice-title"]?.value as? String) ??
            "Ausschreibung"

        // Veröffentlichung
        let publishedAt = DateParser.parse(dict["publication-date"]?.value as? String)

        // Deadline – mehrere mögliche Feldnamen testen
        let deadlineString: String? =
            (dict["submission-deadline-lot"]?.value as? String) ??
            (dict["time-limit-receipt-tenders-lot"]?.value as? String) ??
            (dict["deadline-receipt-tenders-lot"]?.value as? String)
        let deadline = DateParser.parse(deadlineString)

        // Link
        let urlStr = (dict["submission-url-lot"]?.value as? String)
        let url = urlStr.flatMap(URL.init(string:))

        return Tender(
            id: UUID().uuidString,
            source: "TED",
            title: title,
            buyer: nil,
            cpv: [],
            country: country,
            city: nil,
            deadline: deadline,
            publishedAt: publishedAt,
            valueEstimate: nil,
            url: url
        )
    }

    // ---------- Query-Builder ----------
    /// Verwendet FT (Volltext), buyer-country (Länder) und classification-cpv (CPV).
    private func buildExpertQuery(from filters: SearchFilters) -> String {
        var parts: [String] = []

        if !filters.regions.isEmpty {
            let countries = filters.regions
                .map { "\"\($0.uppercased())\"" }
                .joined(separator: ",")
            parts.append("buyer-country IN (\(countries))")
        }

        if !filters.cpv.isEmpty {
            let cpv = filters.cpv
                .map { "\"\($0)\"" }
                .joined(separator: ",")
            parts.append("classification-cpv IN (\(cpv))")
        }

        let text = filters.freeText.trimmingCharacters(in: .whitespacesAndNewlines)
        if !text.isEmpty {
            let escaped = text.replacingOccurrences(of: "\"", with: "\\\"")
            let tokenized = escaped.split(separator: " ").joined(separator: " ")
            parts.append(#"FT~(\#(tokenized))"#)
        }

        return parts.isEmpty ? #"FT~(tender)"# : parts.joined(separator: " AND ")
    }

    // ---------- Fehlerauswertung ----------
    private func isQuerySyntaxError(_ error: Error) -> Bool {
        let msg = (error as NSError).userInfo[NSLocalizedDescriptionKey] as? String ?? ""
        return msg.uppercased().contains("QUERY_SYNTAX_ERROR")
    }
    private func isUnknownFieldError(_ error: Error) -> Bool {
        let msg = (error as NSError).userInfo[NSLocalizedDescriptionKey] as? String ?? ""
        return msg.uppercased().contains("QUERY_UNKNOWN_FIELD")
    }
    private func extractSupportedFields(from error: Error) -> [String]? {
        let msg = (error as NSError).userInfo[NSLocalizedDescriptionKey] as? String ?? ""
        guard let rng = msg.range(of: "supported values are:") else { return nil }
        let list = msg[rng.upperBound...]
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .trimmingCharacters(in: CharacterSet(charactersIn: " ():"))
        return list.split(separator: ",").map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }.filter { !$0.isEmpty }
    }
    private func pickMinimalFieldSet(from supported: [String]) -> [String] {
        var chosen = [String]()
        func pick(_ name: String) { if supported.contains(name) { chosen.append(name) } }
        pick("notice-title")
        pick("buyer-country")
        pick("publication-date")
        // irgendein Deadline-/URL-Feld, wenn verfügbar
        for c in ["submission-deadline-lot","time-limit-receipt-tenders-lot","deadline-receipt-tenders-lot","submission-url-lot"] {
            if supported.contains(c) { chosen.append(c); break }
        }
        if chosen.isEmpty, let first = supported.first { chosen = [first] }
        return Array(Set(chosen))
    }

    // ---------- Async/Await ----------
    func asyncSearch(filters: SearchFilters) async throws -> [Tender] {
        try await withCheckedThrowingContinuation { cont in
            var cancellable: AnyCancellable?
            cancellable = self.search(filters: filters)
                .sink(
                    receiveCompletion: { completion in
                        switch completion {
                        case .finished: break
                        case .failure(let error): cont.resume(throwing: error)
                        }
                        _ = cancellable
                    },
                    receiveValue: { value in
                        cont.resume(returning: value)
                        _ = cancellable
                    }
                )
        }
    }
}
