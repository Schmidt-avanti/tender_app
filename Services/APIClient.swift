import Foundation
import Combine

// Minimales TED-Modell für die Liste
private struct TedNoticeLite: Decodable {
    let id: String?
    let title: String?
    let publicationDate: String?
    let buyerCountry: String?
    let links: LinksContainer?

    struct LinksContainer: Decodable {
        let pdf: String?
        let html: String?
    }
}

private struct TedSearchResponse: Decodable {
    let total: Int?
    let notices: [TedNoticeLite]?
}

/// HTTP-Client für TED Europa (ohne API-Key)
final class APIClient {
    static let shared = APIClient()
    private init() {}

    /// Combine-Variante (bestehende Pipelines bleiben nutzbar)
    func search(filters: SearchFilters) -> AnyPublisher<[Tender], Error> {
        // 1) Expert-Query aus UI-Filtern bauen
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
        if !text.isEmpty {
            terms.append("text:\(text)")
        }

        let expert = terms.isEmpty
            ? "type:contract-notice OR type:contract-award"
            : terms.joined(separator: " AND ")

        // 2) TED erwartet "expertQuery" statt "q"
        let body: [String: Any] = [
            "expertQuery": expert,
            "page": 1,
            "limit": 25,
            "fields": ["id","title","publicationDate","buyerCountry","links.pdf","links.html"]
        ]

        guard let url = URL(string: "https://api.ted.europa.eu/v3/notices/search") else {
            return Fail(error: URLError(.badURL)).eraseToAnyPublisher()
        }

        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.setValue("application/json", forHTTPHeaderField: "Accept")
        req.setValue("TendersApp/1.0 (iOS)", forHTTPHeaderField: "User-Agent")

        do {
            req.httpBody = try JSONSerialization.data(withJSONObject: body)
        } catch {
            return Fail(error: error).eraseToAnyPublisher()
        }

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
            .decode(type: TedSearchResponse.self, decoder: JSONDecoder())
            .map { resp in
                (resp.notices ?? []).map { n in
                    let urlStr = n.links?.pdf ?? n.links?.html
                    return Tender(
                        id: n.id ?? UUID().uuidString,
                        source: "TED",
                        title: n.title ?? "Ohne Titel",
                        buyer: nil,
                        cpv: [],
                        country: n.buyerCountry,
                        city: nil,
                        deadline: nil,          // (Phase 2 via Detail-XML möglich)
                        valueEstimate: nil,     // (Phase 2)
                        url: urlStr.flatMap(URL.init(string:))
                    )
                }
            }
            .receive(on: RunLoop.main)
            .eraseToAnyPublisher()
    }

    /// Async/await-Wrapper
    func asyncSearch(filters: SearchFilters) async throws -> [Tender] {
        try await withCheckedThrowingContinuation { cont in
            var cancellable: AnyCancellable?
            cancellable = self.search(filters: filters)
                .sink(
                    receiveCompletion: { completion in
                        switch completion {
                        case .finished: break
                        case .failure(let error):
                            cont.resume(throwing: error)
                        }
                        _ = cancellable // keep alive bis completion
                    },
                    receiveValue: { value in
                        cont.resume(returning: value)
                        _ = cancellable
                    }
                )
        }
    }
}
