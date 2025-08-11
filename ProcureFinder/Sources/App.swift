import SwiftUI

@main
struct ProcureFinderApp: App {
    // ResultsViewModel benötigt Start-Filter → neutrale Defaults genügen.
    @StateObject private var resultsVM = ResultsViewModel(filters: SearchFilters())

    var body: some Scene {
        WindowGroup {
            // SearchView besitzt sein eigenes SearchViewModel (StateObject).
            // Beim Suchen übergibt es die aktuellen Filter an resultsVM.
            SearchView()
                .environmentObject(resultsVM)
        }
    }
}
