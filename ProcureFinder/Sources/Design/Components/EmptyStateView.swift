import SwiftUI

struct EmptyStateView: View {
    let message: String
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "doc.text.magnifyingglass").font(.system(size: 40))
            Text(message).font(.headline).multilineTextAlignment(.center)
                .accessibilityLabel(message)
        }
        .padding()
    }
}
