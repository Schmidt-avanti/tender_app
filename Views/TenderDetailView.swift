import SwiftUI

/// Displays the full details of a tender.  Users can toggle it as a
/// favourite, write a personal note, schedule a calendar reminder and
/// trigger a test push notification.
struct TenderDetailView: View {
    let tender: Tender
    @EnvironmentObject private var favs: FavoritesManager
    @State private var noteText: String = ""
    @State private var showAlert: Bool = false
    @EnvironmentObject private var bidManager: BidManager
    @State private var showBid: Bool = false
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    Text(tender.title)
                        .font(.title)
                        .bold()
                    Spacer()
                    Button(action: {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                            favs.toggle(tender: tender)
                        }
                    }) {
                        Image(systemName: favs.isFavorite(id: tender.id) ? "star.fill" : "star")
                            .foregroundColor(.yellow)
                            .font(.title2)
                            .scaleEffect(favs.isFavorite(id: tender.id) ? 1.3 : 1.0)
                    }
                    .buttonStyle(.plain)
                }
                if let buyer = tender.buyer {
                    Text("Auftraggeber: \(buyer)")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                if !tender.cpv.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("CPV-Codes:").bold()
                        HStack(spacing: 8) {
                            ForEach(tender.cpv, id: \.self) { code in
                                Pill(text: code)
                            }
                        }
                    }
                }
                if let deadline = tender.deadline {
                    Text("Frist: \(deadline, style: .date)")
                }
                if let estimate = tender.valueEstimate {
                    let formatted = NumberFormatter.localizedString(from: NSNumber(value: estimate), number: .currency)
                    Text("geschätzter Wert: \(formatted)")
                }
                // Notes section
                VStack(alignment: .leading, spacing: 4) {
                    Text("Notiz")
                        .font(.headline)
                    TextEditor(text: $noteText)
                        .frame(height: 100)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color.gray.opacity(0.3))
                        )
                        .onChange(of: noteText) { newValue in
                            favs.setNote(newValue, for: tender.id)
                        }
                        .onAppear {
                            // Preload existing note if available
                            self.noteText = favs.note(for: tender.id)
                        }
                }
                // Action buttons
                HStack(spacing: 20) {
                    Button(action: {
                        CalendarManager.shared.addEvent(for: tender)
                        showAlert = true
                    }) {
                        Label("Termin", systemImage: "calendar.badge.plus")
                    }
                    Button(action: {
                        NotificationManager.shared.requestPermission()
                        NotificationManager.shared.scheduleTestNotification(for: tender)
                    }) {
                        Label("Info", systemImage: "bell.badge")
                    }
                    if let url = tender.url {
                        Link(destination: url) {
                            Label("Original", systemImage: "link")
                        }
                    }
                    // Bid workflow
                    Button(action: {
                        // Create a bid if one doesn't already exist for this tender
                        if let existing = bidManager.bids.first(where: { $0.tender.id == tender.id }) {
                            // navigate to existing bid
                            // Use state to trigger navigation
                            showBid = true
                        } else {
                            let newBid = bidManager.createBid(for: tender)
                            // update state with the new bid's ID
                            showBid = true
                        }
                    }) {
                        Label("Bid", systemImage: "doc.plaintext")
                    }
                }
                .buttonStyle(.bordered)
                .padding(.top, 8)
                Spacer()
            }
            .padding()
        }
        .navigationTitle("Details")
        .navigationBarTitleDisplayMode(.inline)
        .alert(isPresented: $showAlert) {
            Alert(title: Text("Kalender"), message: Text("Termin wurde hinzugefügt."), dismissButton: .default(Text("OK")))
        }
        .navigationDestination(isPresented: $showBid) {
            // Determine the bid; ensure there's always at least one
            if let existing = bidManager.bids.first(where: { $0.tender.id == tender.id }) {
                BidDetailView(bid: existing)
            } else {
                // Should not happen because we create one above
                Text("Keine Bid vorhanden").foregroundColor(.secondary)
            }
        }
    }
}
