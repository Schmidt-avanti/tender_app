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

// ---------- API-Client ----------
final class APIClient {
    static let shared = APIClient()
    private init() {}

    /// Start-Fields: bewusst klein & „typisch“ – Server kann andere verlangen;
    /// dann greifen wir den Fehlertext ab und retryn mit einer zulässigen Auswahl.
    private let preferredFields = [
        "publication-date",     // Veröffentlichungsdatum
        "notice-title",         // Titel
        "buyer-country",        // Land
        "submission-url-lot"    // Link (falls vorhanden)
    ]

    func search(filters: SearchFilters) -> AnyPublisher<[Tender], Error> {
        let q = buildExpertQuery(from: filters)

        // 1. Versuch mit Wunschfeldern
        return performSearch(query: q, fields: preferredFields)
            // Wenn Fields ungültig → unterstützte Liste parsen & retry
            .catch { [weak self] error -> AnyPublisher<[Tender], Error> in
                guard let self else { return Fail(error: error).eraseToAnyPublisher() }
                if let supported = self.extractSupportedFields(from: error), !supported.isEmpty {
                    let minimal = self.pickMinimalFieldSet(from: supported)
                    return self.performSearch(query: q, fields: minimal)
                }
                // Wenn Query-Syntax oder unbekannte Felder → Fallback auf pure Volltextsuche
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

    // ---------- Mapping (robust) ----------
    private func mapDynamicNotice(_ dict: [String: AnyDecodable]) -> Tender {
        let country = (dict["buyer-country"]?.value as? String)

        let urlString =
            (dict["submission-url-lot"]?.value as? String)
        let url = urlString.flatMap(URL.init(string:))

        let title =
            (dict["notice-title"]?.value as? String) ??
            "Ausschreibung \(country ?? "")"

        return Tender(
            id: UUID().uuidString,
            source: "TED",
            title: title,
            buyer: nil,
            cpv: [],                    // (optional in Phase 2)
            country: country,
            city: nil,
            deadline: nil,
            valueEstimate: nil,
            url: url
        )
    }

    // ---------- Query-Builder (konform) ----------
    /// Verwendet FT (Volltext), buyer-country (Länder) und classification-cpv (CPV).
    private func buildExpertQuery(from filters: SearchFilters) -> String {
        var parts: [String] = []

        // Länder -> buyer-country IN ("DE","FR")
        if !filters.regions.isEmpty {
            let countries = filters.regions
                .map { "\"\($0.uppercased())\"" }
                .joined(separator: ",")
            parts.append("buyer-country IN (\(countries))")
        }

        // CPV -> classification-cpv IN ("30200000","79500000")
        if !filters.cpv.isEmpty {
            let cpv = filters.cpv
                .map { "\"\($0)\"" }
                .joined(separator: ",")
            parts.append("classification-cpv IN (\(cpv))")
        }

        // Freitext -> FT~(…)
        let text = filters.freeText.trimmingCharacters(in: .whitespacesAndNewlines)
        if !text.isEmpty {
            let escaped = text.replacingOccurrences(of: "\"", with: "\\\"")
            // FT: beide Wörter müssen vorkommen (Query „~“ entspricht contains AND)
            let tokenized = escaped.split(separator: " ").joined(separator: " ")
            parts.append(#"FT~(\#(tokenized))"#)
        }

        // Falls keine Filter -> neutrale, gültige Volltextsuche
        if parts.isEmpty {
            return #"FT~(tender)"#
        } else {
            return parts.joined(separator: " AND ")
        }
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

    /// Extrahiert die „supported values“-Liste aus einer 400er-Fehlermeldung.
    private func extractSupportedFields(from error: Error) -> [String]? {
        let msg = (error as NSError).userInfo[NSLocalizedDescriptionKey] as? String ?? ""
        guard let rng = msg.range(of: "supported values are:") else { return nil }
        let list = msg[rng.upperBound...]
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .trimmingCharacters(in: CharacterSet(charactersIn: " ():"))
        let tokens = list
            .split(separator: ",")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
        return tokens
    }

    /// Wählt eine minimale, nutzbare Kombination (Titel, Land, URL wenn möglich).
    private func pickMinimalFieldSet(from supported: [String]) -> [String] {
        var chosen = [String]()
        func pick(_ name: String) { if supported.contains(name) { chosen.append(name) } }

        pick("notice-title")
        pick("buyer-country")
        let urlCandidates = [
            "submission-url-lot"
        ]
        if let urlField = urlCandidates.first(where: { supported.contains($0) }) {
            chosen.append(urlField)
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

