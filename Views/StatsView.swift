//
//  StatsView.swift
//  TendersApp
//

import SwiftUI
import Charts

struct StatsView: View {
    @ObservedObject var viewModel: SearchViewModel

    struct Bucket: Identifiable, Hashable {
        var id: String { label }
        let label: String
        let count: Int
    }

    private var buckets: [Bucket] {
        let groups = Dictionary(grouping: viewModel.results, by: { $0.country })
            .map { (key, vals) in Bucket(label: key, count: vals.count) }
            .sorted { $0.count > $1.count }
        return groups
    }

    var body: some View {
        NavigationView {
            VStack {
                if buckets.isEmpty {
                    ContentUnavailableView("Keine Daten", systemImage: "chart.bar", description: Text("Führe zuerst eine Suche aus."))
                        .padding()
                } else {
                    Chart(buckets) { b in
                        BarMark(
                            x: .value("Land", b.label),
                            y: .value("Anzahl", b.count)
                        )
                    }
                    .frame(height: 300)
                    .padding()
                }
                Spacer()
            }
            .navigationTitle("Statistik")
        }
    }
}

#Preview {
    StatsView(viewModel: SearchViewModel())
}
