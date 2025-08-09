import Foundation
import Combine

/// Manages search filters, results and loading state for the v2 app.
final class SearchViewModel: ObservableObject {
    @Published var filters = SearchFilters()
    @Published var results: [Tender] = []
    @Published var isLoading: Bool = false
    @Published var errorMessage: String? = nil
    private var cancellables = Set<AnyCancellable>()

    /// A deduplicated and ranked view of the results.  Duplicate
    /// tenders are removed based on their identifier, and each
    /// remaining tender is assigned a simple relevance score based on
    /// how closely it matches the current filters.  Tenders are then
    /// sorted descending by score.  This provides a rudimentary
    /// "AI ranking" without an external model.
    var rankedResults: [Tender] {
        // Remove duplicates by ID
        var seen: Set<String> = []
        var unique: [Tender] = []
        for tender in results {
            if !seen.contains(tender.id) {
                unique.append(tender)
                seen.insert(tender.id)
            }
        }
        // Compute a naive relevance score: count matches on CPV and region
        func score(for tender: Tender) -> Int {
            var score = 0
            // CPV match weight 2
            for code in filters.cpv {
                if tender.cpv.contains(code) { score += 2 }
            }
            // Region (country) match weight 1
            if let country = tender.country {
                if filters.regions.contains(where: { $0.caseInsensitiveCompare(country) == .orderedSame }) {
                    score += 1
                }
            }
            // Free text match: if the title contains free text (case insensitive) add weight
            let free = filters.freeText.trimmingCharacters(in: .whitespacesAndNewlines)
            if !free.isEmpty && tender.title.localizedCaseInsensitiveContains(free) {
                score += 2
            }
            return score
        }
        return unique.sorted { score(for: $0) > score(for: $1) }
    }
    func runSearch() {
        isLoading = true
        errorMessage = nil
        APIClient.shared.search(filters: filters)
            .sink { [weak self] completion in
                self?.isLoading = false
                if case .failure(let error) = completion {
                    self?.errorMessage = error.localizedDescription
                }
            } receiveValue: { [weak self] data in
                self?.results = data
            }
            .store(in: &cancellables)
    }
}
