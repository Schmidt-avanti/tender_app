import SwiftUI

/// Displays all bids created by the user.  Each bid shows the
/// associated tender title and current status.  Selecting a bid
/// navigates to a detail screen where tasks and comments can be
/// managed.
struct BidListView: View {
    @EnvironmentObject private var bidManager: BidManager

    var body: some View {
        NavigationStack {
            List {
                ForEach(bidManager.bids) { bid in
                    NavigationLink(value: bid.id) {
                        VStack(alignment: .leading) {
                            Text(bid.tender.title)
                                .font(.headline)
                            Text(bid.status.rawValue)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                .onDelete { offsets in
                    for index in offsets {
                        let id = bidManager.bids[index].id
                        bidManager.remove(id: id)
                    }
                }
            }
            .navigationTitle("Bids")
            .navigationDestination(for: UUID.self) { bidID in
                if let bid = bidManager.bid(for: bidID) {
                    BidDetailView(bid: bid)
                } else {
                    Text("Bid not found").foregroundColor(.secondary)
                }
            }
        }
    }
}

struct BidListView_Previews: PreviewProvider {
    static var previews: some View {
        BidListView()
            .environmentObject(BidManager.shared)
    }
}