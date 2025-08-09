import SwiftUI
import UserNotifications

/// App-Entry für die TendersApp.
/// Injiziert die benötigten EnvironmentObjects und fragt Notification-Rechte an.
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
                    // Benachrichtigungsberechtigung einmalig anfragen
                    NotificationManager.shared.requestPermission()
                }
        }
    }
}
