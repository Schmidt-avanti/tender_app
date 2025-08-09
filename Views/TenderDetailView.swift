import SwiftUI

struct TenderDetailView: View {
    @EnvironmentObject var bidManager: BidManager
    let tender: Tender

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                Text(tender.title)
                    .font(.title2)
                    .bold()

                if let buyer = tender.buyer, !buyer.isEmpty {
                    Label(buyer, systemImage: "building.2")
                }

                if let loc = tender.location, !loc.isEmpty {
                    Label(loc, systemImage: "mappin.and.ellipse")
                }

                if let d = tender.deadline {
                    Label("Frist: \(format(date: d))", systemImage: "calendar")
                }

                if let b = tender.budget, !b.isEmpty {
                    Label("Budget: \(b)", systemImage: "eurosign.circle")
                }

                if let url = tender.url {
                    Link(destination: url) {
                        Label("Zur Ausschreibung", systemImage: "safari")
                            .font(.headline)
                    }
                    .padding(.top, 8)
                }

                if let s = tender.summary, !s.isEmpty {
                    Divider().padding(.vertical, 6)
                    Text(s).font(.body)
                }

                Divider().padding(.vertical, 8)

                Button {
                    _ = bidManager.createBid(for: tender)
                } label: {
                    Label("Gebot anlegen", systemImage: "plus.circle.fill")
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                }
                .buttonStyle(.borderedProminent)
            }
            .padding()
        }
        .navigationTitle("Details")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func format(date: Date) -> String {
        let f = DateFormatter()
        f.dateStyle = .medium
        return f.string(from: date)
    }
}