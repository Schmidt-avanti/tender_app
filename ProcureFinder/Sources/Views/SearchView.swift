import SwiftUI

struct SearchView: View {
    @EnvironmentObject var vm: SearchViewModel
    @EnvironmentObject var resultsVM: ResultsViewModel
    @EnvironmentObject var cpvRepo: CPVRepository

    @State private var showCPV = false

    var body: some View {
        VStack(spacing: 8) {
            HStack {
                TextField(L10n.t(.searchTitle), text: $vm.filters.text)
                    .textFieldStyle(.roundedBorder)
                    .accessibilityLabel(L10n.t(.searchTitle))
                Button(L10n.t(.filters)) { vm.isFilterSheet = true }
                    .buttonStyle(.bordered)
            }
            .padding(.horizontal)

            HStack {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack {
                        ForEach(vm.filters.cpvCodes, id: \.self) { code in
                            TagView(text: code)
                        }
                    }.padding(.horizontal)
                }
                Button("CPV") { showCPV = true }.buttonStyle(.bordered)
            }

            Button(L10n.t(.apply)) {
                Task { await resultsVM.run(filters: vm.filters, reset: true) }
            }
            .buttonStyle(.borderedProminent)
            .padding(.horizontal)

            ResultsView()
                .environmentObject(resultsVM)
                .refreshable { await resultsVM.run(filters: vm.filters, reset: true) }
        }
        .sheet(isPresented: $showCPV) {
            CPVPickerView(selected: $vm.filters.cpvCodes)
                .environmentObject(cpvRepo)
        }
        .sheet(isPresented: $vm.isFilterSheet) {
            FilterSheet(filters: $vm.filters)
        }
        .navigationTitle("ProcureFinder")
    }
}

struct FilterSheet: View {
    @Binding var filters: SearchFilters
    var body: some View {
        NavigationStack {
            Form {
                Section("Zeitraum") {
                    HStack {
                        Button("7 Tage") { setDays(7) }
                        Button("30 Tage") { setDays(30) }
                        Button("90 Tage") { setDays(90) }
                    }
                    DatePicker("Von", selection: Binding(get: { filters.dateFrom ?? Date() },
                                                         set: { filters.dateFrom = $0 }), displayedComponents: .date)
                    DatePicker("Bis", selection: Binding(get: { filters.dateTo ?? Date() },
                                                         set: { filters.dateTo = $0 }), displayedComponents: .date)
                }
                Section("Sortierung") {
                    Picker("Sort", selection: $filters.sort) {
                        Text("Datum absteigend").tag(SearchFilters.Sort.dateDesc)
                        Text("Datum aufsteigend").tag(SearchFilters.Sort.dateAsc)
                    }.pickerStyle(.segmented)
                }
            }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Schließen") { dismiss() } }
            }
        }
    }
    @Environment(\.dismiss) private var dismiss
    private func setDays(_ d: Int) {
        let to = Date()
        let from = Calendar.current.date(byAdding: .day, value: -d, to: to)!
        filters.dateFrom = from; filters.dateTo = to
    }
}
