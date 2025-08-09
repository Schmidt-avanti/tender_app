import Foundation

@MainActor
final class SearchViewModel: ObservableObject {
    @Published var query: String = ""
    @Published var isSearching = false
    @Published var results: [Tender] = []
    @Published var errorMessage: String? = nil

    private let openai = OpenAIClient()
    private var provider: SearchProvider
    private let fetcher = PageFetcher()
    private let extractor = TenderExtractor()

    init(provider: SearchProvider? = nil) {
        if let serpKey = ProcessInfo.processInfo.environment["SERP_API_KEY"], !serpKey.isEmpty {
            self.provider = SerpAPIProvider(apiKey: serpKey)
        } else if let bingKey = ProcessInfo.processInfo.environment["BING_API_KEY"], !bingKey.isEmpty {
            self.provider = BingWebSearchProvider(apiKey: bingKey)
        } else if !AppSecrets.serpApiKey.isEmpty {
            self.provider = SerpAPIProvider()
        } else if !AppSecrets.bingApiKey.isEmpty {
            self.provider = BingWebSearchProvider()
        } else {
            self.provider = LocalMockSearchProvider()
        }
    }

    func performSearch() async {
        errorMessage = nil
        isSearching = true
        results = []
        defer { isSearching = false }

        let expandedQuery: String
        do {
            expandedQuery = try await expandQuery(query)
        } catch {
            expandedQuery = query
        }

        do {
            let urls = try await provider.search(query: expandedQuery, limit: 5)
            var found: [Tender] = []
            for url in urls {
                do {
                    let text = try await fetcher.fetchPlainText(from: url)
                    if let t = try await extractor.extract(from: text, sourceURL: url) {
                        found.append(t)
                    }
                } catch {
                    // ignore per-URL errors
                }
            }
            if found.isEmpty && provider is LocalMockSearchProvider {
                found = [Tender.mock]
            }
            results = found
            if results.isEmpty {
                errorMessage = "Keine passenden Ausschreibungen gefunden."
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func expandQuery(_ q: String) async throws -> String {
        let sys = "Du verbesserst Suchanfragen für öffentliche Ausschreibungen. Antworte NUR mit der finalen Suchphrase."
        let user = "Verbessere folgende Suchanfrage für relevante EU-/DACH-Ausschreibungen (keine Werbung, nur seriöse Quellen): "\(q)". Nutze deutschsprachige Keywords + CPV-ähnliche Begriffe."
        let out = try await openai.complete(systemPrompt: sys, userPrompt: user, model: .gpt4oMini, temperature: 0.2)
        return out.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}