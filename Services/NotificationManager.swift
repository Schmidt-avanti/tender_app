import Foundation
import UserNotifications

/// Handles requesting notification permissions and scheduling local
/// notifications.  In a production app you would forward requests to
/// your backend to trigger remote push notifications via APNs.
final class NotificationManager {
    static let shared = NotificationManager()
    private init() {}
    
    /// Request authorisation to send local notifications.  Should be
    /// called early in the app lifecycle.
    func requestPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            if let error = error {
                print("Notification permission error: \(error)")
            } else {
                print("Notification permission granted: \(granted)")
            }
        }
    }
    
    /// Schedule a simple local notification a few seconds in the future.
    func scheduleTestNotification(for tender: Tender) {
        let content = UNMutableNotificationContent()
        content.title = tender.title
        if let buyer = tender.buyer {
            content.subtitle = buyer
        }
        content.body = "Neue Ausschreibung verfügbar!"
        content.sound = .default
        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 5, repeats: false)
        let request = UNNotificationRequest(identifier: tender.id, content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Failed to schedule notification: \(error)")
            }
        }
    }
}
