import Foundation
import CoreData
import OSLog

final class NoticeRepository {
    private let client = TedClient.shared
    private let log = Logger(subsystem: "ProcureFinder", category: "Repo")
    private var currentPage = 1
    private var canLoadMore = true
    private var lastQuery: String = ""

    func search(filters: SearchFilters, reset: Bool) async throws -> [Notice] {
        let query = Self.buildExpertQuery(filters: filters)
        if reset || query != lastQuery {
            currentPage = 1; canLoadMore = true; lastQuery = query
            try? await clearCache()
        }
        guard canLoadMore else { return [] }
        let req = TedSearchRequest(query: query, page: currentPage, limit: 25, sort: filters.sort.rawValue, fields: ["ND","PD","TI","CY","PT","CPV","EV","buyer"])
        let res = try await client.search(request: req)
        if (res.count ?? 0) < 25 { canLoadMore = false } else { currentPage += 1 }
        let notices: [Notice] = res.results.compactMap { dto in
            Notice(
                publicationNumber: dto.publicationNumber ?? UUID().uuidString,
                title: dto.title ?? "—",
                country: dto.country,
                procedure: dto.procedure,
                cpvTop: dto.cpvTop,
                budget: dto.budget,
                publicationDate: Self.parse(dateString: dto.publicationDate)
            )
        }
        await cache(notices: notices)
        return notices
    }

    func hasMore() -> Bool { canLoadMore }

    private static func parse(dateString: String?) -> Date? {
        guard let s = dateString else { return nil }
        let f = ISO8601DateFormatter(); return f.date(from: s)
    }

    // Expert query builder based on TED help (FT, CPV, CY, PD, PT)
    static func buildExpertQuery(filters: SearchFilters) -> String {
        var parts: [String] = []
        if !filters.text.isEmpty {
            // FT for full text with quotes
            parts.append("FT=\"\(filters.text.replacingOccurrences(of: "\"", with: "\\\""))\"")
        }
        if !filters.countries.isEmpty {
            let list = filters.countries.map { "\($0)" }.joined(separator: " OR ")
            parts.append("CY IN (\(list))")
        }
        if !filters.cpvCodes.isEmpty {
            let list = filters.cpvCodes.joined(separator: " OR ")
            parts.append("CPV IN (\(list))")
        }
        if let from = filters.dateFrom, let to = filters.dateTo {
            let df = ISO8601DateFormatter(); df.formatOptions = [.withFullDate]
            parts.append("PD=[\(df.string(from: from)) TO \(df.string(from: to))]")
        }
        if !filters.procedures.isEmpty {
            let list = filters.procedures.joined(separator: " OR ")
            parts.append("PT IN (\(list))")
        }
        if parts.isEmpty { parts.append("FT=*") }
        return parts.joined(separator: " AND ")
    }

    // MARK: - Core Data Cache
    private var context: NSManagedObjectContext { CoreDataStack.shared.context }

    private func cache(notices: [Notice]) async {
        await context.perform {
            for n in notices {
                let e = NoticeEntity(context: self.context)
                e.publicationNumber = n.publicationNumber
                e.title = n.title
                e.country = n.country
                e.procedure = n.procedure
                e.cpvTop = n.cpvTop
                e.budget = n.budget ?? 0
                e.publicationDate = n.publicationDate
                e.isFavorite = false
            }
            try? self.context.save()
        }
    }

    func cachedNotices() async -> [Notice] {
        await context.perform {
            let req: NSFetchRequest<NoticeEntity> = NoticeEntity.fetchRequest()
            req.sortDescriptors = [NSSortDescriptor(key: "publicationDate", ascending: false)]
            let items = (try? self.context.fetch(req)) ?? []
            return items.map { Notice(
                publicationNumber: $0.publicationNumber ?? "",
                title: $0.title ?? "",
                country: $0.country,
                procedure: $0.procedure,
                cpvTop: $0.cpvTop,
                budget: $0.budget == 0 ? nil : $0.budget,
                publicationDate: $0.publicationDate
            )}
        }
    }

    private func clearCache() async throws {
        try await context.perform {
            let fetch: NSFetchRequest<NSFetchRequestResult> = NoticeEntity.fetchRequest()
            let del = NSBatchDeleteRequest(fetchRequest: fetch)
            try self.context.execute(del)
        }
    }
}
