import SwiftUI
import Charts

/// Shows a simple bar chart summarising the current search results by
/// region.  The data comes from the injected `SearchViewModel`.  If
/// there are no results a placeholder text is displayed instead of
/// the chart.
struct StatsView: View {
    @ObservedObject var viewModel: SearchViewModel
    
    struct RegionCount: Identifiable {
        let id: String
        let count: Int
    }
    
    private var counts: [RegionCount] {
        var map: [String: Int] = [:]
        // Use the rankedResults from the view model to ensure unique entries
        for tender in viewModel.rankedResults {
            let region = tender.country ?? "Unbekannt"
            map[region, default: 0] += 1
        }
        return map.map { RegionCount(id: $0.key, count: $0.value) }.sorted { $0.count > $1.count }
    }
    
    var body: some View {
        NavigationStack {
            VStack {
                if counts.isEmpty {
                    Text("Keine Daten verfügbar")
                        .foregroundColor(.secondary)
                } else {
                    Chart(counts) { item in
                        BarMark(
                            x: .value("Region", item.id),
                            y: .value("Anzahl", item.count)
                        )
                    }
                    .chartXAxisLabel("Region")
                    .chartYAxisLabel("Anzahl")
                    .frame(height: 300)
                    .padding()
                }
                Spacer()
            }
            .navigationTitle("Statistik")
        }
    }
}
