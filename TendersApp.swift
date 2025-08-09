import SwiftUI

@main
struct TendersApp: App {
    // Alle benötigten Models einmalig erzeugen und in den View-Tree geben
    @StateObject private var searchVM = SearchViewModel()
    @StateObject private var bidManager = BidManager()
    @StateObject private var savedSearchManager = SavedSearchManager()

    init() {
        // Optional: Navigationsleiste transparent halten (wir malen selbst Hintergrund)
        let nav = UINavigationBarAppearance()
        nav.configureWithTransparentBackground()
        UINavigationBar.appearance().standardAppearance = nav
        UINavigationBar.appearance().scrollEdgeAppearance = nav
    }

    var body: some Scene {
        WindowGroup {
            ZStack {
                // Vollflächiger Hintergrund (unter Safe Areas)
                Color(uiColor: .systemBackground)
                    .ignoresSafeArea()

                // Deine eigentliche App
                RootView()
            }
            // EnvironmentObjects bereitstellen (sonst Crash)
            .environmentObject(searchVM)
            .environmentObject(bidManager)
            .environmentObject(savedSearchManager)
        }
    }
}
