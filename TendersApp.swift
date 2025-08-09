import SwiftUI
import UserNotifications

/// App-Entry ohne Favoriten-Feature (vorerst deaktiviert)
@main
struct TendersAppV2: App {
    @StateObject private var savedSearches = SavedSearchManager.shared
    @StateObject private var bidManager = BidManager.shared

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(savedSearches)
                .environmentObject(bidManager)
                .onAppear {
                    // Benachrichtigungsrechte anfragen (einmalig)
                    NotificationManager.shared.requestPermission()
                }
        }
    }
}
