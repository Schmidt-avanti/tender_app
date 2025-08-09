import SwiftUI

/// Displays a list of all favourited tenders.  Users can tap to view
/// details, edit notes or unfavourite.  Favourites are persisted
/// locally via `FavoritesManager`.
struct FavoritesView: View {
    @EnvironmentObject private var favs: FavoritesManager
    
    var body: some View {
        NavigationStack {
            Group {
                if favs.items.isEmpty {
                    VStack(spacing: 12) {
                        Text("Keine Favoriten")
                            .font(.title2)
                            .foregroundColor(.secondary)
                        Text("Markiere Ausschreibungen mit dem Stern, um sie hier zu speichern.")
                            .font(.subheadline)
                            .multilineTextAlignment(.center)
                            .foregroundColor(.secondary)
                    }
                    .padding()
                } else {
                    List {
                        ForEach(favs.items.values.sorted(by: { $0.tender.title < $1.tender.title }), id: \.tender.id) { fav in
                            NavigationLink(value: fav.tender) {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(fav.tender.title)
                                        .font(.headline)
                                    if !fav.note.isEmpty {
                                        Text(fav.note)
                                            .font(.subheadline)
                                            .foregroundColor(.secondary)
                                            .lineLimit(2)
                                    }
                                }
                            }
                        }
                        .onDelete { indexSet in
                            for index in indexSet {
                                let fav = favs.items.values.sorted(by: { $0.tender.title < $1.tender.title })[index]
                                favs.remove(id: fav.tender.id)
                            }
                        }
                    }
                    .listStyle(.plain)
                }
            }
            .navigationTitle("Favoriten")
            .navigationDestination(for: Tender.self) { tender in
                TenderDetailView(tender: tender)
            }
        }
    }
}
