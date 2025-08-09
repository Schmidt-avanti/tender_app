import Foundation

protocol SearchProvider {
    func search(query: String, limit: Int) async throws -> [URL]
    var name: String { get }
}

final class LocalMockSearchProvider: SearchProvider {
    let name = "MockProvider"
    func search(query: String, limit: Int) async throws -> [URL] {
        return [
            URL(string: "https://example.com/tender/123")!
        ]
    }
}

final class SerpAPIProvider: SearchProvider {
    let name = "SerpAPI"
    private let apiKey: String
    private let session: URLSession

    init(apiKey: String = AppSecrets.serpApiKey, session: URLSession = .shared) {
        self.apiKey = apiKey
        self.session = session
    }

    func search(query: String, limit: Int) async throws -> [URL] {
        guard !apiKey.isEmpty else {
            throw NSError(domain: "SerpAPI", code: -10, userInfo: [NSLocalizedDescriptionKey: "SERP_API_KEY fehlt."])
        }
        var comps = URLComponents(string: "https://serpapi.com/search.json")!
        comps.queryItems = [
            .init(name: "engine", value: "google"),
            .init(name: "q", value: query),
            .init(name: "num", value: "\(max(1, min(limit, 10)))"),
            .init(name: "api_key", value: apiKey)
        ]
        let (data, resp) = try await session.data(from: comps.url!)
        guard let http = resp as? HTTPURLResponse, (200...299).contains(http.statusCode) else {
            let txt = String(data: data, encoding: .utf8) ?? ""
            throw NSError(domain: "SerpAPI", code: (resp as? HTTPURLResponse)?.statusCode ?? -1, userInfo: [NSLocalizedDescriptionKey: "SerpAPI-Fehler: \(txt)"])
        }
        struct Res: Decodable { let organic_results: [Item]? }
        struct Item: Decodable { let link: String? }
        let decoded = try JSONDecoder().decode(Res.self, from: data)
        let links = (decoded.organic_results ?? []).compactlyMap { $0.link }.compactMap { URL(string: $0) }
        return Array(links.prefix(limit))
    }
}

final class BingWebSearchProvider: SearchProvider {
    let name = "BingWebSearch"
    private let apiKey: String
    private let session: URLSession

    init(apiKey: String = AppSecrets.bingApiKey, session: URLSession = .shared) {
        self.apiKey = apiKey
        self.session = session
    }

    func search(query: String, limit: Int) async throws -> [URL] {
        guard !apiKey.isEmpty else {
            throw NSError(domain: "BingWebSearch", code: -10, userInfo: [NSLocalizedDescriptionKey: "BING_API_KEY fehlt."])
        }
        var comps = URLComponents(string: "https://api.bing.microsoft.com/v7.0/search")!
        comps.queryItems = [
            .init(name: "q", value: query),
            .init(name: "count", value: "\(max(1, min(limit, 10)))")
        ]
        var req = URLRequest(url: comps.url!)
        req.setValue(apiKey, forHTTPHeaderField: "Ocp-Apim-Subscription-Key")
        let (data, resp) = try await session.data(for: req)
        guard let http = resp as? HTTPURLResponse, (200...299).contains(http.statusCode) else {
            let txt = String(data: data, encoding: .utf8) ?? ""
            throw NSError(domain: "BingWebSearch", code: (resp as? HTTPURLResponse)?.statusCode ?? -1, userInfo: [NSLocalizedDescriptionKey: "Bing-Fehler: \(txt)"])
        }
        struct Root: Decodable { let webPages: WebPages? }
        struct WebPages: Decodable { let value: [Item]? }
        struct Item: Decodable { let url: String? }
        let root = try JSONDecoder().decode(Root.self, from: data)
        let urls = (root.webPages?.value ?? []).compactlyMap { $0.url }.compactMap { URL(string: $0) }
        return Array(urls.prefix(limit))
    }
}

private extension Array {
    func compactlyMap<T>(_ transform: (Element) -> T?) -> [T] {
        var result: [T] = []
        result.reserveCapacity(count)
        for el in self {
            if let v = transform(el) { result.append(v) }
        }
        return result
    }
}