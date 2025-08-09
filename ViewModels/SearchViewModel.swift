import Foundation
import Combine

/// Manages search filters, results and loading state.
@MainActor
final class SearchViewModel: ObservableObject {
    @Published var filters = SearchFilters()
    @Published var results: [Tender] = []
    @Published var isLoading: Bool = false
    @Published var errorMessage: String? = nil

    private var cancellables = Set<AnyCancellable>()
    private var currentSearch: AnyCancellable?

    /// A deduplicated and ranked view of the results.
    /// Duplicate tenders are removed by id and the remainder is sorted
    /// by a simple relevance score derived from the active filters.
    var rankedResults: [Tender] {
        // De-dupe
        var seen = Set<String>()
        var unique: [Tender] = []
        for tender in results where !seen.contains(tender.id) {
            unique.append(tender)
            seen.insert(tender.id)
        }

        // Naive scoring
        func score(for tender: Tender) -> Int {
            var s = 0
            // CPV matches weigh 2
            for code in filters.cpv {
                if tender.cpv.contains(code) { s += 2 }
            }
            // Region (country) match weighs 1
            if let country = tender.country,
               filters.regions.contains(where: { $0.caseInsensitiveCompare(country) == .orderedSame }) {
                s += 1
            }
            // Free text in title weighs 2
            let free = filters.freeText.trimmingCharacters(in: .whitespacesAndNewlines)
            if !free.isEmpty, tender.title.localizedCaseInsensitiveContains(free) {
                s += 2
            }
            return s
        }

        return unique.sorted { score(for: $0) > score(for: $1) }
    }

    /// Update filters and immediately run a new search.
    func updateFilters(_ newFilters: SearchFilters) {
        filters = newFilters
        runSearch()
    }

    /// Triggers a new search using the current filters.
    func runSearch() {
        // Cancel a possibly running search to avoid race conditions.
        currentSearch?.cancel()

        isLoading = true
        errorMessage = nil

        currentSearch = APIClient.shared.search(filters: filters)
            .receive(on: DispatchQueue.main) // extra safety even with @MainActor
            .sink { [weak self] completion in
                guard let self else { return }
                self.isLoading = false
                if case .failure(let error) = completion {
                    self.errorMessage = error.localizedDescription
                }
            } receiveValue: { [weak self] data in
                self?.results = data
            }
    }
}
