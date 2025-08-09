import SwiftUI

struct TenderDetailView: View {
    @EnvironmentObject var bidManager: BidManager
    let tender: Tender

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text(tender.title)
                    .font(.title)
                    .fontWeight(.semibold)

                if let desc = tender.description, !desc.isEmpty {
                    Text(desc)
                        .font(.body)
                        .foregroundColor(.secondary)
                }

                Divider()

                Button {
                    _ = bidManager.createBid(for: tender)
                } label: {
                    Label("Gebot anlegen", systemImage: "plus.circle.fill")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
            }
            .padding()
        }
        .navigationTitle("Ausschreibung")
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    // Dummy Tender für Preview
    let sample = Tender(id: "T-123", title: "Beispiel-Ausschreibung", description: "Kurze Beschreibung.")
    return NavigationView {
        TenderDetailView(tender: sample)
            .environmentObject(BidManager.shared)
    }
}


