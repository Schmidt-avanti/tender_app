import Foundation
import OSLog

@MainActor
final class ResultsViewModel: ObservableObject {
    @Published var notices: [Notice] = []
    @Published var loading = false
    @Published var error: String? = nil

    private let repo = NoticeRepository()

    func run(filters: SearchFilters, reset: Bool = true) async {
        loading = true; error = nil
        do {
            let new = try await repo.search(filters: filters, reset: reset)
            if reset { notices = new } else { notices.append(contentsOf: new) }
        } catch {
            self.error = error.localizedDescription
        }
        loading = false
    }

    func loadMoreIfNeeded(current: Notice) async {
        guard let last = notices.last, last.id == current.id else { return }
        await run(filters: SearchFilters(), reset: false)
    }
}
