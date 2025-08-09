import SwiftUI

/// Detailansicht einer Ausschreibung inklusive Metadaten,
/// Favorit, Notizfeld, Kalender- und Benachrichtigungsaktionen sowie Bid-Workflow.
struct TenderDetailView: View {
    let tender: Tender

    @EnvironmentObject private var favs: FavoritesManager
    @EnvironmentObject private var bidManager: BidManager

    @State private var noteText: String = ""
    @State private var showCalendarAlert: Bool = false
    @State private var showBid: Bool = false

    // MARK: - Body
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {

                // Titel + Favoriten
                HStack(alignment: .top) {
                    Text(tender.title)
                        .font(.largeTitle.bold())
                        .lineLimit(3)
                    Spacer(minLength: 8)
                    Button {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                            favs.toggle(tender: tender)
                        }
                    } label: {
                        Image(systemName: favs.isFavorite(id: tender.id) ? "star.fill" : "star")
                            .foregroundColor(.yellow)
                            .font(.title2)
                            .scaleEffect(favs.isFavorite(id: tender.id) ? 1.2 : 1.0)
                            .accessibilityLabel(favs.isFavorite(id: tender.id) ? "Als Favorit markiert" : "Als Favorit markieren")
                    }
                    .buttonStyle(.plain)
                }

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

                // Optional: Auftraggeber & CPV
                if let buyer = tender.buyer {
                    Divider().padding(.vertical, 2)
                    Label("Auftraggeber: \(buyer)", systemImage: "building.2")
                        .foregroundStyle(.secondary)
                        .font(.callout)
                }

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

                // Notizen
                VStack(alignment: .leading, spacing: 6) {
                    Text("Notiz")
                        .font(.headline)
                    TextEditor(text: $noteText)
                        .frame(minHeight: 110)
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(Color.gray.opacity(0.25), lineWidth: 1)
                        )
                        .onChange(of: noteText) { newValue in
                            favs.setNote(newValue, for: tender.id)
                        }
                        .onAppear {
                            noteText = favs.note(for: tender.id)
                        }
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
                        // existierenden Bid öffnen oder neu anlegen
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
        // Navigation zu Bid-Detail
        .navigationDestination(isPresented: $showBid) {
            if let bid = bidManager.bids.first(where: { $0.tender.id == tender.id }) {
                BidDetailView(bid: bid)
            } else {
                // Fallback – sollte praktisch nicht auftreten
                Text("Keine Bid vorhanden")
                    .foregroundColor(.secondary)
            }
        }
    }
}
