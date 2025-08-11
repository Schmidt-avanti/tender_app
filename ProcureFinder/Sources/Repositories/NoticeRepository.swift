import Foundation
import OSLog

/// Repository kapselt TED-Client + Pagination + (optional) Persistenz.
final class NoticeRepository {

    private let client: TedClient
    private let log = Logger(subsystem: "ProcureFinder", category: "NoticeRepository")

    private var currentPage: Int = 0
    private var lastFilters: SearchFilters?

    init(client: TedClient = .shared) {
        self.client = client
    }

    func reset() {
        currentPage = 0
        lastFilters = nil
    }

    /// Suche mit Query & Filtern. Setze `reset: true` bei neuer Suche.
    @discardableResult
    func search(query: String, filters: SearchFilters, reset: Bool) async throws -> [Notice] {
        var f = filters
        f.text = query

        if reset || lastFilters != f {
            currentPage = 0
            lastFilters = f
        }

        let page = currentPage
        log.debug("Search page \(page, privacy: .public)")

        let items = try await client.searchNotices(filters: f, page: page, pageSize: 25)

        // Pagination: nächste Seite erst beim nächsten Aufruf
        currentPage += 1
        return items
    }
}

