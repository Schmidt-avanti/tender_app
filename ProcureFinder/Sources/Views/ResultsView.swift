import SwiftUI

struct ResultsView: View {
    @EnvironmentObject var resultsVM: ResultsViewModel

    var body: some View {
        Group {
            if resultsVM.isLoading && resultsVM.items.isEmpty {
                // Initialer Ladevorgang
                VStack { Spacer(); ProgressView(); Spacer() }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if let err = resultsVM.errorMessage, resultsVM.items.isEmpty {
                // Fehler-Zustand
                VStack(spacing: 12) {
                    Text(err).multilineTextAlignment(.center).padding(.horizontal)
                    Button("Erneut versuchen") {
                        Task { await resultsVM.load(reset: true) }
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if resultsVM.items.isEmpty {
                // Leerer Zustand
                VStack(spacing: 8) {
                    Text("Keine Ergebnisse").font(.headline)
                    Text("Passe Filter oder Suchtext an.").font(.subheadline)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                // Ergebnisliste
                List {
                    ForEach(resultsVM.items) { notice in
                        NavigationLink(destination: NoticeDetailView(notice: notice)) {
                            NoticeRow(notice: notice)
                                .onAppear {
                                    Task { await resultsVM.loadMoreIfNeeded(current: notice) }
                                }
                        }
                    }

                    if resultsVM.isLoading {
                        HStack { Spacer(); ProgressView(); Spacer() }
                            .listRowSeparator(.hidden)
                    }
                }
                .listStyle(.plain)
                .refreshable { await resultsVM.refresh() }
            }
        }
        .task {
            // Initial laden, falls noch nichts vorhanden
            if resultsVM.items.isEmpty {
                await resultsVM.load(reset: true)
            }
        }
    }
}
