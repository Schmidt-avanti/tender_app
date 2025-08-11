import SwiftUI
import OSLog

@main
struct ProcureFinderApp: App {
    @StateObject private var searchVM = SearchViewModel()
    @StateObject private var resultsVM = ResultsViewModel()
    @StateObject private var cpvRepo = CPVRepository()
    init() {
        CoreDataStack.shared.bootstrap()
    }
    var body: some Scene {
        WindowGroup {
            NavigationStack {
                SearchView()
                    .environmentObject(searchVM)
                    .environmentObject(resultsVM)
                    .environmentObject(cpvRepo)
            }
            .task {
                await cpvRepo.loadCPV()
            }
        }
    }
}
