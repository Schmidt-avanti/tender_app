import SwiftUI

@main
struct TendersApp: App {
    @StateObject private var bidManager = BidManager.shared
    @StateObject private var searchVM = SearchViewModel()

    var body: some Scene {
        WindowGroup {
            NavigationView {
                RootView()
                    .environmentObject(bidManager)
                    .environmentObject(searchVM)
            }
        }
    }
}