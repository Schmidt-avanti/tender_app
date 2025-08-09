import SwiftUI

/// Detailansicht einer Ausschreibung (ohne Favoriten/Notizen).
/// Zeigt Metadaten, Link, Kalender/Notification-Aktionen und Bid-Workflow.
struct TenderDetailView: View {
    let tender: Tender

    @EnvironmentObject private var bidManager: BidManager

    @State private var showCalendarAlert: Bool = false
    @State private var showBid: Bool = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {

                // Titel
                Text(tender.title)
                    .font(.largeTitle.bold())
                    .lineLimit(3)

                // Metadaten
                VStack(alignment: .leading, spacing: 6) {
                    if let pub = tender.publishedAt {
                        Label("Veröffentlicht: \(pub.formatted(date: .abbreviated, time: .omitted))", systemImage: "calendar")
                    }
                    if let dl = tender.deadline {
                        Label("Abgabe: \(dl.formatted(date: .abbreviated, time: .omitted))", systemImage: "clock")
                    }
                    if let country = tender.country {
                        Label("Land: \(country)", systemImage: "globe.europe.africa")
                    }
                    if let url = tender.url {
                        Link(destination: url) {
                            Label("Zur Ausschreibung (TED)", systemImage: "safari")
                        }
                    }
                }
                .font(.callout)
                .foregroundStyle(.secondary)

                // CPV (optional)
                if !tender.cpv.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("CPV-Codes")
                            .font(.headline)
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 8) {
                                ForEach(tender.cpv, id: \.self) { code in
                                    Pill(text: code)
                                }
                            }
                        }
                    }
                }

                if let estimate = tender.valueEstimate {
                    let formatted = NumberFormatter.localizedString(from: NSNumber(value: estimate), number: .currency)
                    Label("Geschätzter Wert: \(formatted)", systemImage: "eurosign.circle")
                        .foregroundStyle(.secondary)
                        .font(.callout)
                }

                // Aktionen
                HStack(spacing: 14) {
                    Button {
                        CalendarManager.shared.addEvent(for: tender)
                        showCalendarAlert = true
                    } label: {
                        Label("Termin", systemImage: "calendar.badge.plus")
                    }

                    Button {
                        NotificationManager.shared.requestPermission()
                        NotificationManager.shared.scheduleTestNotification(for: tender)
                    } label: {
                        Label("Info", systemImage: "bell.badge")
                    }

                    if let url = tender.url {
                        Link(destination: url) {
                            Label("Original", systemImage: "link")
                        }
                    }

                    Button {
                        if bidManager.bids.first(where: { $0.tender.id == tender.id }) == nil {
                            _ = bidManager.createBid(for: tender)
                        }
                        showBid = true
                    } label: {
                        Label("Bid", systemImage: "doc.plaintext")
                    }
                }
                .buttonStyle(.bordered)
                .padding(.top, 4)

                Spacer(minLength: 12)
            }
            .padding()
        }
        .navigationTitle("Details")
        .navigationBarTitleDisplayMode(.inline)
        .alert(isPresented: $showCalendarAlert) {
            Alert(
                title: Text("Kalender"),
                message: Text("Termin wurde hinzugefügt."),
                dismissButton: .default(Text("OK"))
            )
        }
        .navigationDestination(isPresented: $showBid) {
            if let bid = bidManager.bids.first(where: { $0.tender.id == tender.id }) {
                BidDetailView(bid: bid)
            } else {
                Text("Keine Bid vorhanden")
                    .foregroundColor(.secondary)
            }
        }
    }
}

