import SwiftUI

@main
struct TendersApp: App {
    @StateObject private var bidManager = BidManager.shared

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(bidManager)
        }
    }
}
