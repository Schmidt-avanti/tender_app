import SwiftUI
import SafariServices

struct ResultsView: View {
    @EnvironmentObject var resultsVM: ResultsViewModel

    var body: some View {
        Group {
            if resultsVM.loading && resultsVM.notices.isEmpty {
                ProgressView()
            } else if let err = resultsVM.error {
                ErrorStateView(message: err, retry: { Task { await resultsVM.run(filters: SearchFilters()) } })
            } else if resultsVM.notices.isEmpty {
                EmptyStateView(message: L10n.t(.empty))
            } else {
                ScrollView {
                    LazyVStack {
                        ForEach(resultsVM.notices) { n in
                            NavigationLink(value: n) {
                                NoticeRow(notice: n)
                                    .onAppear { Task { await resultsVM.loadMoreIfNeeded(current: n) } }
                            }
                        }
                    }.padding(.horizontal)
                }
            }
        }
        .navigationDestination(for: Notice.self) { n in
            NoticeDetailView(notice: n)
        }
    }
}
