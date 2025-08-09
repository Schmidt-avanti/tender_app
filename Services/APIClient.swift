import Foundation
import Combine

/// A simple HTTP client used to talk to the backend.  Encodes
/// `SearchFilters` into JSON and decodes an array of `Tender` from the
/// response.  Dates are decoded as ISO8601.
final class APIClient {
    static let shared = APIClient()

    private init() {}

    /// Represents a minimal notice returned from the TED search API.
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

    /// Performs a search against the TED Europa API using the provided filters.
    /// The TED API does not require authentication.  We build an expert query
    /// string based on selected countries, CPV codes and free text.  Deadline
    /// and value filters are not supported directly by TED and are therefore
    /// ignored in this basic implementation.
    func search(filters: SearchFilters) -> AnyPublisher<[Tender], Error> {
        // Construct the expert query string
        var terms: [String] = []
        if !filters.regions.isEmpty {
            let countries = filters.regions.map { $0.uppercased() }.joined(separator: " OR ")
            terms.append("(buyerCountry:\(countries))")
        }
        if !filters.cpv.isEmpty {
            let cpv = filters.cpv.joined(separator: " OR ")
            terms.append("(cpvCode:\(cpv))")
        }
        let trimmedText = filters.freeText.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmedText.isEmpty {
            // quote the text to handle spaces properly
            terms.append("text:\(trimmedText)")
        }
        let q: String
        if terms.isEmpty {
            // default to contract notices and awards if no specific filters
            q = "type:contract-notice OR type:contract-award"
        } else {
            q = terms.joined(separator: " AND ")
        }
        let body: [String: Any] = [
            "q": q,
            "page": 1,
            "limit": 25,
            "fields": ["id", "title", "publicationDate", "buyerCountry", "links.pdf", "links.html"]
        ]
        guard let url = URL(string: "https://api.ted.europa.eu/v3/notices/search") else {
            return Fail(error: URLError(.badURL)).eraseToAnyPublisher()
        }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: body, options: [])
        } catch {
            return Fail(error: error).eraseToAnyPublisher()
        }
        return URLSession.shared.dataTaskPublisher(for: request)
            .tryMap { output in
                guard let http = output.response as? HTTPURLResponse,
                      (200..<300).contains(http.statusCode) else {
                    throw URLError(.badServerResponse)
                }
                return output.data
            }
            .decode(type: TedSearchResponse.self, decoder: JSONDecoder())
            .map { response in
                let notices = response.notices ?? []
                return notices.map { n -> Tender in
                    // map missing fields gracefully
                    let id = n.id ?? UUID().uuidString
                    let title = n.title ?? "Ohne Titel"
                    let country = n.buyerCountry
                    let pdf = n.links?.pdf
                    let html = n.links?.html
                    let urlStr = pdf ?? html
                    let url = urlStr.flatMap { URL(string: $0) }
                    return Tender(
                        id: id,
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
            }
            .receive(on: RunLoop.main)
            .eraseToAnyPublisher()
    }
}
