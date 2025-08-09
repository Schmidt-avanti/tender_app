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
    if !text.isEmpty { terms.append("text:\(text)") }

    let expert = terms.isEmpty
      ? "type:contract-notice OR type:contract-award"
      : terms.joined(separator: " AND ")

    // 2) KORREKT: Feld heißt "query"
    let body: [String: Any] = [
        "query": expert,
        "page": 1,
        "limit": 25
        // Hinweis: 'fields' weglassen – einige Gateways reagieren darauf allergisch
    ]

    guard let url = URL(string: "https://api.ted.europa.eu/v3/notices/search") else {
        return Fail(error: URLError(.badURL)).eraseToAnyPublisher()
    }

    var req = URLRequest(url: url)
    req.httpMethod = "POST"
    req.setValue("application/json", forHTTPHeaderField: "Content-Type")
    req.setValue("application/json", forHTTPHeaderField: "Accept")
    req.setValue("TendersApp/1.0 (iOS)", forHTTPHeaderField: "User-Agent")

    do { req.httpBody = try JSONSerialization.data(withJSONObject: body) }
    catch { return Fail(error: error).eraseToAnyPublisher() }

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
                    deadline: nil,
                    valueEstimate: nil,
                    url: urlStr.flatMap(URL.init(string:))
                )
            }
        }
        .receive(on: RunLoop.main)
        .eraseToAnyPublisher()
}
