import Foundation
import Combine

/// A simple HTTP client used to talk to the backend.  Encodes
/// `SearchFilters` into JSON and decodes an array of `Tender` from the
/// response.  Dates are decoded as ISO8601.
@MainActor
final class APIClient {
    static let shared = APIClient()
    /// The base URL of the backend.  Adjust this when running against
    /// a remote server or simulator.
    var baseURL = URL(string: "http://localhost:8000")!
    private let session: URLSession
    private init() {
        session = URLSession(configuration: .default)
    }
    /// Performs a search using Combine.  This method is preserved for
    /// compatibility with existing code and returns a publisher.  New
    /// clients should prefer `asyncSearch` instead.
    func search(filters: SearchFilters) -> AnyPublisher<[Tender], Error> {
        var request = URLRequest(url: baseURL.appendingPathComponent("/search"))
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        do {
            request.httpBody = try JSONEncoder().encode(filters)
        } catch {
            return Fail(error: error).eraseToAnyPublisher()
        }
        return session.dataTaskPublisher(for: request)
            .map { $0.data }
            .tryMap { data -> [Tender] in
                let decoder = JSONDecoder()
                decoder.dateDecodingStrategy = .iso8601
                return try decoder.decode([Tender].self, from: data)
            }
            .receive(on: DispatchQueue.main)
            .eraseToAnyPublisher()
    }

    /// Performs a search using Swift's async/await concurrency model.
    /// This method should be preferred by new code as it simplifies
    /// error handling and call sites.  It returns an array of
    /// `Tender` on success or throws an error if the network call
    /// fails or decoding fails.
    func asyncSearch(filters: SearchFilters) async throws -> [Tender] {
        var request = URLRequest(url: baseURL.appendingPathComponent("/search"))
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONEncoder().encode(filters)
        let (data, _) = try await session.data(for: request)
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try decoder.decode([Tender].self, from: data)
    }
}
