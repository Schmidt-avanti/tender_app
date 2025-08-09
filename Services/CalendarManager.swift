import Foundation
import EventKit

/// Provides a simplified interface to create calendar events for tender
/// deadlines.  The user will be prompted to grant access to the
/// calendar when calling `addEvent`.
final class CalendarManager {
    static let shared = CalendarManager()
    private let eventStore = EKEventStore()
    
    private init() {}
    
    /// Adds an event to the default calendar on the tender's deadline.
    func addEvent(for tender: Tender) {
        guard let deadline = tender.deadline else { return }
        eventStore.requestAccess(to: .event) { granted, error in
            if let error = error {
                print("Calendar access error: \(error)")
                return
            }
            guard granted else {
                print("Calendar access not granted")
                return
            }
            let event = EKEvent(eventStore: self.eventStore)
            event.title = tender.title
            event.startDate = deadline
            // Assume 1 hour duration
            event.endDate = deadline.addingTimeInterval(3600)
            event.notes = tender.buyer
            event.calendar = self.eventStore.defaultCalendarForNewEvents
            do {
                try self.eventStore.save(event, span: .thisEvent)
                print("Event saved")
            } catch {
                print("Failed to save event: \(error)")
            }
        }
    }
}
