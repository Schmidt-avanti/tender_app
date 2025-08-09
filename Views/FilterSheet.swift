import SwiftUI

/// Sheet for configuring search filters.  Bound to a `SearchFilters`
/// instance supplied by the parent view.  When closed via the
/// confirmation action it triggers the provided callback.
struct FilterSheet: View {
    @Binding var filters: SearchFilters
    var onApply: () -> Void
    @State private var cpvInput: String = ""
    @State private var regionInput: String = ""
    var body: some View {
        NavigationStack {
            Form {
                Section("Freitext") {
                    TextField("z. B. Callcenter, Hotline", text: $filters.freeText)
                }
                Section("CPV-Codes") {
                    HStack {
                        TextField("z. B. 79512000-6", text: $cpvInput)
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled(true)
                        Button("Hinzufügen") {
                            let trimmed = cpvInput.trimmingCharacters(in: .whitespacesAndNewlines)
                            guard !trimmed.isEmpty else { return }
                            filters.cpv.append(trimmed)
                            cpvInput = ""
                        }
                        .buttonStyle(.borderless)
                    }
                    if !filters.cpv.isEmpty {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 8) {
                                ForEach(filters.cpv, id: \.self) { code in
                                    Pill(text: code)
                                }
                            }
                        }.padding(.vertical, 4)
                    }
                }
                Section("Regionen") {
                    HStack {
                        TextField("z. B. DE, AT, CH", text: $regionInput)
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled(true)
                        Button("Hinzufügen") {
                            let trimmed = regionInput.trimmingCharacters(in: .whitespacesAndNewlines)
                            guard !trimmed.isEmpty else { return }
                            filters.regions.append(trimmed)
                            regionInput = ""
                        }
                        .buttonStyle(.borderless)
                    }
                    if !filters.regions.isEmpty {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 8) {
                                ForEach(filters.regions, id: \.self) { reg in
                                    Pill(text: reg)
                                }
                            }
                        }.padding(.vertical, 4)
                    }
                }
                Section("Fristen") {
                    DatePicker(
                        "Frühestens",
                        selection: Binding(
                            get: { filters.deadlineFrom ?? Date() },
                            set: { filters.deadlineFrom = $0 }
                        ),
                        displayedComponents: .date
                    )
                    DatePicker(
                        "Spätestens",
                        selection: Binding(
                            get: { filters.deadlineTo ?? Date() },
                            set: { filters.deadlineTo = $0 }
                        ),
                        displayedComponents: .date
                    )
                }
                Section("Wert (optional)") {
                    HStack {
                        Text("Min")
                        Spacer()
                        TextField("0", value: $filters.minValue, format: .number)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                    }
                    HStack {
                        Text("Max")
                        Spacer()
                        TextField("", value: $filters.maxValue, format: .number)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                    }
                }
            }
            .navigationTitle("Filter")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Übernehmen") {
                        onApply()
                    }
                }
                ToolbarItem(placement: .cancellationAction) {
                    Button("Abbrechen") {
                        onApply()
                    }
                }
            }
        }
    }
}
