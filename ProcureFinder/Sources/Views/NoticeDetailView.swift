import SwiftUI
import SafariServices

struct NoticeDetailView: View {
    @StateObject private var vm: DetailViewModel
    init(notice: Notice) { _vm = StateObject(wrappedValue: DetailViewModel(notice: notice)) }
    var body: some View {
        List {
            Section("Allgemein") {
                Text(vm.notice.title).font(.headline)
                if let d = vm.notice.publicationDate { Text(d.formatted(date: .abbreviated, time: .omitted)) }
                if let c = vm.notice.country { Text(c) }
                if let p = vm.notice.procedure { Text(p) }
                if let cpv = vm.notice.cpvTop { Text("CPV: \(cpv)") }
                if let b = vm.notice.budget { Text("Budget: €\(Int(b))") }
            }
            Section("Links") {
                Link(L10n.t(.openHTML), destination: vm.htmlURL)
                Link(L10n.t(.openPDF), destination: vm.pdfURL)
            }
            Section("Aktion") {
                ShareLink(item: vm.htmlURL)
            }
        }
        .navigationTitle("Detail")
    }
}
