import Foundation
import Combine

/// Einfacher HTTP-Client für die Suche.
/// - Encodiert `SearchFilters` als JSON
/// - Decodiert `[Tender]` aus der Antwort
/// - Datumsformat: ISO8601
final class APIClient {

    static let shared = APIClient()

    /// Basis-URL deines Backends (für lokale Tests ggf. anpassen)
    var baseURL = URL(string: "http://localhost:8000")!

    private let session: URLSession

    private init() {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 30
        config.timeoutIntervalForResource = 60
        self.session = URLSession(configuration: config)
    }

    // MARK: - Helpers

    private func jsonEncoder() -> JSONEncoder {
        let enc = JSONEncoder()
        enc.dateEncodingStrategy = .iso8601
        return enc
    }

    private func jsonDecoder() -> JSONDecoder {
        let dec = JSONDecoder()
        dec.dateDecodingStrategy = .iso8601
        return dec
    }

    private func makeSearchRequest(for filters: SearchFilters) throws -> URLRequest {
        var request = URLRequest(url: baseURL.appendingPathComponent("/search"))
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try jsonEncoder().encode(filters)
        return request
    }

    // MARK: - Combine (bestehende Aufrufer bleiben kompatibel)

    /// Combine-Variante. Für neue Aufrufer lieber `asyncSearch` nutzen.
    func search(filters: SearchFilters) -> AnyPublisher<[Tender], Error> {
        do {
            let request = try makeSearchRequest(for: filters)
            return session.dataTaskPublisher(for: request)
                .tryMap { output -> [Tender] in
                    try self.jsonDecoder().decode([Tender].self, from: output.data)
                }
                // Ergebnisse am Main-Thread liefern, damit UI sicher aktualisiert
                .receive(on: DispatchQueue.main)
                .eraseToAnyPublisher()
        } catch {
            return Fail(error: error).eraseToAnyPublisher()
        }
    }

    // MARK: - async/await (empfohlen)

    /// Moderne Async/Await-Variante.
    /// Wirft Fehler bei Netzwerk-/Decode-Problemen.
    func asyncSearch(filters: SearchFilters) async throws -> [Tender] {
        let request = try makeSearchRequest(for: filters)
        let (data, _) = try await session.data(for: request)
        return try jsonDecoder().decode([Tender].self, from: data)
    }
}
