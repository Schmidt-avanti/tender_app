import SwiftUI

struct TagView: View {
    let text: String
    var body: some View {
        Text(text)
            .font(.caption)
            .padding(.horizontal, 8).padding(.vertical, 4)
            .background(Capsule().fill(Theme.secondaryBG))
            .accessibilityLabel(text)
    }
}
