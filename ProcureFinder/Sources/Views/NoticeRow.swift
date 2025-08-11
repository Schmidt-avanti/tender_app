import SwiftUI

struct NoticeRow: View {
    let notice: Notice
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(notice.title).font(.headline).lineLimit(3)
            HStack(spacing: 8) {
                if let c = notice.country { TagView(text: c) }
                if let p = notice.procedure { TagView(text: p) }
                if let cpv = notice.cpvTop { TagView(text: cpv) }
                if let b = notice.budget { TagView(text: String(format: "€%.0f", b)) }
            }
            .accessibilityElement(children: .combine)
        }
        .padding(.vertical, 8)
        .accessibilityLabel("\(notice.title)")
    }
}
