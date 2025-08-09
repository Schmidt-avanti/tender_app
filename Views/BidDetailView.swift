import SwiftUI

/// Detailansicht für ein Bid (ohne Favorites-Bezug).
struct BidDetailView: View {
    let bid: Bid

    @EnvironmentObject private var bidManager: BidManager

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {

                // Tender-Kopf
                VStack(alignment: .leading, spacing: 6) {
                    Text(bid.tender.title)
                        .font(.title.bold())
                        .fixedSize(horizontal: false, vertical: true)

                    Text(bid.tender.subtitleLine)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                Divider()

                // Bid-Infos (minimal – passe an deinen Bid später an)
                VStack(alignment: .leading, spacing: 8) {
                    Text("Status: \(bid.status.rawValue.capitalized)")
                    Text("Erstellt: \(bid.createdAt.formatted(date: .abbreviated, time: .shortened))")
                }
                .font(.callout)
                .foregroundStyle(.secondary)

                if let url = bid.tender.url {
                    Link(destination: url) {
                        Label("Zur Ausschreibung", systemImage: "link")
                    }
                    .buttonStyle(.bordered)
                }

                Spacer(minLength: 12)
            }
            .padding()
        }
        .navigationTitle("Bid")
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - Preview (ohne FavoritesManager)
#Preview {
    let sampleTender = Tender(
        id: "demo",
        source: "TED",
        title: "Beispiel-Ausschreibung",
        buyer: "Musterstadt",
        cpv: ["79530000"],
        country: "DE",
        city: "Berlin",
        deadline: Calendar.current.date(byAdding: .day, value: 10, to: Date()),
        publishedAt: Date(),
        valueEstimate: 100000,
        url: URL(string: "https://ted.europa.eu")
    )

    let sampleBid = Bid(
        id: "bid-1",
        tender: sampleTender,
        status: .preparing,
        createdAt: Date()
    )

    return NavigationStack {
        BidDetailView(bid: sampleBid)
            .environmentObject(BidManager.shared)
    }
}
