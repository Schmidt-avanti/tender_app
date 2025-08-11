import Foundation

@MainActor
final class SearchViewModel: ObservableObject {
    @Published var filters = SearchFilters()
    @Published var isFilterSheet = false

    func preset(days: Int) {
        let to = Date()
        let from = Calendar.current.date(byAdding: .day, value: -days, to: to)!
        filters.dateFrom = from; filters.dateTo = to
    }
}
