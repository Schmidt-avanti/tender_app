import SwiftUI

struct BidDetailView: View {
    let bid: Bid

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(bid.title).font(.title2).bold()
            Text("Status: \(bid.status.rawValue.capitalized)").foregroundColor(.secondary)
            Text("Angelegt: \(format(date: bid.createdAt))").foregroundColor(.secondary)
            Spacer()
        }
        .padding()
        .navigationTitle("Gebot")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func format(date: Date) -> String {
        let f = DateFormatter()
        f.dateStyle = .medium
        f.timeStyle = .short
        return f.string(from: date)
    }
}