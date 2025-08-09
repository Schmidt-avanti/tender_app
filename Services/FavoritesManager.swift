import SwiftUI

/// Liste der Favoriten auf Basis der leichtgewichtigen Snapshots aus `FavoritesManager`.
struct FavoritesView: View {
    @EnvironmentObject private var favorites: FavoritesManager
    @EnvironmentObject private var bidManager: BidManager

    var body: some View {
        NavigationStack {
            Group {
                if favorites.items.isEmpty {
                    VStack(spacing: 12) {
                        Image(systemName: "star")
                            .font(.system(size: 36, weight: .regular))
                            .foregroundColor(.secondary)
                        Text("Keine Favoriten")
                            .font(.title3)
                            .foregroundColor(.secondary)
                        Text("Tippe im Treffer auf den Stern, um eine Ausschreibung zu speichern.")
                            .multilineTextAlignment(.center)
                            .foregroundColor(.secondary)
                    }
                    .padding()
                } else {
                    List {
                        ForEach(sortedFavorites, id: \.id) { f in
                            NavigationLink(value: f) {
                                HStack(alignment: .top, spacing: 12) {
                                    VStack(alignment: .leading, spacing: 6) {
                                        Text(displayTitle(for: f))
                                            .font(.headline)
                                            .lineLimit(2)

                                        if let note = f.note, !note.isEmpty {
                                            Text(note)
                                                .font(.subheadline)
                                                .foregroundColor(.secondary)
                                                .lineLimit(1)
                                        }
                                    }

                                    Spacer(minLength: 8)

                                    Button {
                                        withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                                            favorites.toggle(tender: makeTender(from: f))
                                        }
                                    } label: {
                                        Image(systemName: "star.fill")
                                            .foregroundColor(.yellow)
                                            .font(.title3)
                                    }
                                    .buttonStyle(.plain)
                                }
                                .padding(.vertical, 6)
                            }
                        }
                        .onDelete(perform: delete)
                    }
                    .listStyle(.plain)
                }
            }
            .navigationTitle("Favoriten")
            .navigationDestination(for: FavoritesManager.FavoriteData.self) { f in
                TenderDetailView(tender: makeTender(from: f))
            }
        }
    }

    // MARK: - Helpers

    /// Sortierung nach Titel (fallback: ID)
    private var sortedFavorites: [FavoritesManager.FavoriteData] {
        favorites.items.values
            .sorted { displayTitle(for: $0).localizedCaseInsensitiveCompare(displayTitle(for: $1)) == .orderedAscending }
    }

    private func delete(at offsets: IndexSet) {
        for idx in offsets {
            let f = sortedFavorites[idx]
            favorites.items.removeValue(forKey: f.id)
        }
    }

    private func displayTitle(for f: FavoritesManager.FavoriteData) -> String {
        f.title.isEmpty ? "Ausschreibung" : f.title
    }

    /// Baut einen minimalen `Tender` aus dem Snapshot, damit Navigation/Detail funktionieren.
    private func makeTender(from f: FavoritesManager.FavoriteData) -> Tender {
        Tender(
            id: f.id,
            source: "TED",
            title: displayTitle(for: f),
            buyer: nil,
            cpv: [],
            country: nil,
            city: nil,
            deadline: nil,
            publishedAt: nil,
            valueEstimate: nil,
            url: f.url.flatMap(URL.init(string:))
        )
    }
}

