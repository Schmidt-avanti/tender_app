import Foundation
import Combine

// Antworthülle so generisch wie möglich
private struct TedSearchResponseDynamic: Decodable {
    let total: Int?
    let notices: [ [String: AnyDecodable] ]?

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        self.total = try c.decodeIfPresent(Int.self, forKey: .total)
        self.notices = try c.decodeIfPresent([ [String: AnyDecodable] ].self, forKey: .notices)
    }
    enum CodingKeys: String, CodingKey { case total, notices }
}

// Minimaler „AnyDecodable“ für dynamische Feldwerte
private struct AnyDecodable: Decodable {
    let value: Any
    init(from decoder: Decoder) throws {
        let c = try decoder.singleValueContainer()
        if let s = try? c.decode(String.self) { value = s; return }
        if let i = try? c.decode(Int.self) { value = i; return }
        if let d = try? c.decode(Double.self) { value = d; return }
        if let b = try? c.decode(Bool.self) { value = b; return }
        if let dict = try? c.decode([String: AnyDecodable].self) {
            value = dict.mapValues { $0.value }; return
        }
        if let arr = try? c.decode([AnyDecodable].self) {
            value = arr.map { $0.value }; return
        }
        value = NSNull()
    }
}

/// HTTP-Client für TED Europa (ohne API-Key).
/// Robust: passt `fields` bei 400-Fehlern aus der Serverfehlermeldung automatisch an.
final class APIClient {
    static let shared = APIClient()
    private init() {}

    // Start-Kandidaten (häufig vorhanden)
    private let preferredFields: [String] = [
        // häufige eForms Felder:
        "BT-24-NoticeTitle",            // Titel (wenn vorhanden)
        "country-buyer",                // Land des Auftraggebers
        "submission-url-lot",           // URL zum Los (Nutzerlink)
        // Fallback-URLs (verschiedene Gateways)
        "touchpoint-internet-address-paying",
        "touchpoint-internet-address-fiscal-legis-lot",
        // Metadaten
        "publication-date-notice"
    ]

    func search(filters: SearchFilters) -> AnyPublisher<[Tender], Error> {
        let query = buildExpertQuery(from: filters)
        // erster Versuch mit unseren Wunschfeldern
        return performSearch(query: query, fields: preferredFields)
            .catch { [weak self] error -> AnyPublisher<[Tender], Error> in
                guard
                    let self,
                    let retryFields = self.extractSupportedFields(from: error),
                    !retryFields.isEmpty
                else {
                    return Fail(error: error).eraseToAnyPublisher()
                }
                // sichere Minimalmenge wählen: Land + irgendein URL-Feld, optional Title
                let minimal = self.pickMinimalFieldSet(from: retryFields)
                return self.performSearch(query: query, fields: minimal)
            }
            .eraseToAnyPublisher()
    }

    // MARK: - Request

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
                    // Fehlermeldung mitschicken (wird für das Auto-Retry geparst)
                    let message = String(data: out.data, encoding: .utf8) ?? "HTTP \(http.statusCode)"
                    throw NSError(domain: "TEDSearch", code: http.statusCode,
                                  userInfo: [NSLocalizedDescriptionKey: message])
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

    // MARK: - Mapping

    private func mapDynamicNotice(_ dict: [String: AnyDecodable]) -> Tender {
        // Versuche sinnvolle Felder zu finden
        let country = (dict["country-buyer"]?.value as? String)
        // URL aus mehreren möglichen Feldern
        let urlString =
            (dict["submission-url-lot"]?.value as? String) ??
            (dict["touchpoint-internet-address-paying"]?.value as? String) ??
            (dict["touchpoint-internet-address-fiscal-legis-lot"]?.value as? String)
        let url = urlString.flatMap(URL.init(string:))

        // Titel-Varianten
        let title =
            (dict["BT-24-NoticeTitle"]?.value as? String) ??
            "Ausschreibung \(country ?? "")"

        // Datum (wenn vorhanden)
        let _ = dict["publication-date-notice"]?.value as? String

        return Tender(
            id: UUID().uuidString,    // Falls kein ID-Feld angefordert wurde
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

    // MARK: - Query builder

    private func buildExpertQuery(from filters: SearchFilters) -> String {
        var terms: [String] = []
        if !filters.regions.isEmpty {
            let countries = filters.regions.map { $0.uppercased() }.joined(separator: " OR ")
            terms.append("(buyerCountry:\(countries))")
        }
        if !filters.cpv.isEmpty {
            let cpv = filters.cpv.joined(separator: " OR ")
            terms.append("(cpvCode:\(cpv))")
        }
        let text = filters.freeText.trimmingCharacters(in: .whitespacesAndNewlines)
        if !text.isEmpty { terms.append("text:\(text)") }
        return terms.isEmpty
            ? "type:contract-notice OR type:contract-award"
            : terms.joined(separator: " AND ")
    }

    // MARK: - Fehlerauswertung & Feldauswahl

    /// Extrahiert aus einer 400-Fehlermeldung die „supported values“-Liste.
    private func extractSupportedFields(from error: Error) -> [String]? {
        let msg = (error as NSError).userInfo[NSLocalizedDescriptionKey] as? String ?? ""
        guard let range = msg.range(of: "supported values are:") else { return nil }
        let list = msg[range.upperBound...]
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .trimmingCharacters(in: CharacterSet(charactersIn: " ():"))
        // split an Kommas, trimmen
        let tokens = list
            .split(separator: ",")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
        return tokens
    }

    /// Wählt eine minimale, nutzbare Kombination aus den unterstützten Feldern.
    /// Ziel: mindestens ein Land und eine URL.
    private func pickMinimalFieldSet(from supported: [String]) -> [String] {
        var chosen = [String]()
        func pick(_ name: String) { if supported.contains(name) { chosen.append(name) } }

        // bevorzugt Titel, Land und eine URL
        pick("BT-24-NoticeTitle")
        pick("country-buyer")
        // eine von mehreren möglichen URL-Spalten
        let urlCandidates = [
            "submission-url-lot",
            "touchpoint-internet-address-paying",
            "touchpoint-internet-address-fiscal-legis-lot"
        ]
        if let urlField = urlCandidates.first(where: { supported.contains($0) }) {
            chosen.append(urlField)
        }
        // falls gar nichts gepickt wurde, nimm einfach das erste unterstützte Feld, um die Validierung zu erfüllen
        if chosen.isEmpty, let first = supported.first { chosen = [first] }
        return Array(Set(chosen)) // de-dupe
    }

    // MARK: - Async/Await-Wrapper

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
