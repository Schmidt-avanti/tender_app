import SwiftUI
import UserNotifications

/// The entry point for the second version of the Tenders app.  It
/// uses a tabbed interface to separate search, favourites and
/// statistics into dedicated screens.
@main
struct TendersAppV2: App {
    @StateObject private var favs = FavoritesManager.shared
    @StateObject private var savedSearches = SavedSearchManager.shared
    @StateObject private var bidManager = BidManager.shared
    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(favs)
                .environmentObject(savedSearches)
                .environmentObject(bidManager)
                .onAppear {
                    // Request notification permission when the app starts
                    NotificationManager.shared.requestPermission()
                }
        }
    }
}
