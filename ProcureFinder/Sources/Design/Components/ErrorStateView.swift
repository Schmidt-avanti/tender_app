import SwiftUI

struct ErrorStateView: View {
    let message: String
    let retry: (() -> Void)?
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "exclamationmark.triangle").font(.system(size: 40))
            Text(message).font(.headline).multilineTextAlignment(.center)
                .accessibilityLabel(message)
            if let retry { Button("Retry", action: retry) }
        }
        .padding()
    }
}
