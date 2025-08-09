import SwiftUI

@main
struct TendersApp: App {
    var body: some Scene {
        WindowGroup {
            ZStack {
                Color(.systemBackground).ignoresSafeArea()   // bis in Statusbar & Home-Indicator
                RootView()
            }
        }
    }
}
