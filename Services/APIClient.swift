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

    // Wunschfelder (werden ggf. per Server-Fehlerliste ersetzt)
    private let preferredFields = [
        "BT-24-NoticeTitle",
        "country-buyer",
        "submission-url-lot",
        "touchpoint-internet-address-paying",
        "touchpoint-internet-address-fiscal-legis-lot",
        "publication-date-notice"
    ]

    func search(filters: SearchFilters) -> AnyPublisher<[Tender], Error> {
        let q = buildExpertQuery(from: filters)

        // 1. Versuch mit Wunschfeldern
        return performSearch(query: q, fields: preferredFields)
            // Wenn Query-Syntax-Fehler → automatische, garantiert gültige Fallback-Query
            .catch { [weak self] error -> AnyPublisher<[Tender], Error> in
                guard let self else { return Fail(error: error).eraseToAnyPublisher() }
                if self.isQuerySyntaxError(error) {
                    let fallbackQ = #"type = "contract-notice""#
                    return self.performSearch(query: fallbackQ, fields: self.preferredFields)
                }
                // Wenn Fields ungültig → aus Fehlermeldung unterstützte Felder ziehen und retry
                if let supported = self.extractSupportedFields(from: error), !supported.isEmpty {
                    let minimal = self.pickMinimalFieldSet(from: supported)
                    return self.performSearch(query: q, fields: minimal)
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

    private func mapDynamicNotice(_ dict: [String: AnyDecodable]) -> Tender {
        let country = (dict["country-buyer"]?.value as? String)

        let urlString =
            (dict["submission-url-lot"]?.value as? String) ??
            (dict["touchpoint-internet-address-paying"]?.value as? String) ??
            (dict["touchpoint-internet-address-fiscal-legis-lot"]?.value as? String)
        let url = urlString.flatMap(URL.init(string:))

        let title =
            (dict["BT-24-NoticeTitle"]?.value as? String) ??
            "Ausschreibung \(country ?? "")"

        return Tender(
            id: UUID().uuidString,
            source: "TED",
            title: title,
            buyer: nil,
            cpv: [],
            country: country,
            city: nil,
            deadline: nil,
            valueEstimate: nil,
            url: url
        )
    }

    // ---------- Query-Builder (neue Syntax!) ----------
    private func buildExpertQuery(from filters: SearchFilters) -> String {
        var parts: [String] = []

        if !filters.regions.isEmpty {
            // buyerCountry IN ("DE","FR")
            let countries = filters.regions
                .map { "\"\($0.uppercased())\"" }
                .joined(separator: ",")
            parts.append("buyerCountry IN (\(countries))")
        }

        if !filters.cpv.isEmpty {
            // cpvCode IN ("30200000","79500000")
            let cpv = filters.cpv
                .map { "\"\($0)\"" }
                .joined(separator: ",")
            parts.append("cpvCode IN (\(cpv))")
        }

        let text = filters.freeText.trimmingCharacters(in: .whitespacesAndNewlines)
        if !text.isEmpty {
            // enthält: text ~ "..."
            let escaped = text.replacingOccurrences(of: "\"", with: "\\\"")
            parts.append(#"text ~ "\#(escaped)""#)
        }

        if parts.isEmpty {
            // Default: gültige Syntax
            return #"type IN ("contract-notice","contract-award")"#
        } else {
            return parts.joined(separator: " AND ")
        }
    }

    // ---------- Fehlerauswertung ----------
    private func isQuerySyntaxError(_ error: Error) -> Bool {
        let msg = (error as NSError).userInfo[NSLocalizedDescriptionKey] as? String ?? ""
        return msg.uppercased().contains("QUERY_SYNTAX_ERROR")
    }

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

    private func pickMinimalFieldSet(from supported: [String]) -> [String] {
        var chosen = [String]()
        func pick(_ name: String) { if supported.contains(name) { chosen.append(name) } }
        pick("BT-24-NoticeTitle")
        pick("country-buyer")
        let urlCandidates = [
            "submission-url-lot",
            "touchpoint-internet-address-paying",
            "touchpoint-internet-address-fiscal-legis-lot"
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
