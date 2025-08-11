import Foundation
import OSLog

final class ResultsViewModel: ObservableObject {

    // MARK: - Inputs & State
    @Published var items: [Notice] = []
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?

    var filters: SearchFilters
    private let repo: NoticeRepository
    private let log = Logger(subsystem: "ProcureFinder", category: "ResultsVM")

    // MARK: - Init
    init(filters: SearchFilters,
         repo: NoticeRepository = NoticeRepository()) {
        self.filters = filters
        self.repo = repo
    }

    // MARK: - Loading
    /// Lädt Daten (bei `reset: true` wird die Liste ersetzt & Pagination zurückgesetzt)
    @MainActor
    func load(reset: Bool = false) async {
        guard !isLoading else { return }
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            let new = try await repo.search(query: filters.text,
                                            filters: filters,
                                            reset: reset)
            if reset {
                items = new
            } else {
                items.append(contentsOf: new)
            }
        } catch {
            log.error("Load failed: \(error.localizedDescription, privacy: .public)")
            errorMessage = error.localizedDescription
        }
    }

    /// Pull-to-Refresh
    @MainActor
    func refresh() async {
        await load(reset: true)
    }

    /// Nächste Seite für Endless-Scroll laden
    @MainActor
    func loadMoreIfNeeded(current item: Notice?) async {
        guard let item = item else { return }
        let thresholdIndex = items.index(items.endIndex, offsetBy: -5, limitedBy: items.startIndex) ?? items.startIndex
        if items.firstIndex(of: item) == thresholdIndex {
            await load(reset: false)
        }
    }
}
