import SwiftUI

struct BidListView: View {
    @EnvironmentObject var bidManager: BidManager

    var body: some View {
        List {
            ForEach(bidManager.bids) { bid in
                NavigationLink(destination: BidDetailView(bid: bid)) {
                    VStack(alignment: .leading) {
                        Text(bid.title).font(.headline)
                        Text(bid.status.rawValue.capitalized)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
        .navigationTitle("Gebote")
    }
}