import SwiftUI

@main
struct TendersApp: App {
    var body: some Scene {
        WindowGroup {
            RootView()
                .background(Color(.systemBackground))   // Hintergrund wie System
                .ignoresSafeArea()                       // bis in die Statusbar malen
        }
    }
}
