import SwiftUI

/// A pill shaped label used to display metadata such as CPV codes.  Uses
/// a subtle background colour for contrast and works in both dark and
/// light mode.
struct Pill: View {
    let text: String
    var body: some View {
        Text(text)
            .font(.caption)
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(
                Capsule().fill(Color(.systemGray5))
            )
    }
}

/// A primary button adopting the platform's default prominent style.
struct PrimaryButton: View {
    let title: String
    let action: () -> Void
    var body: some View {
        Button(action: action) {
            Text(title).bold().frame(maxWidth: .infinity)
        }
        .buttonStyle(.borderedProminent)
        .controlSize(.large)
        .cornerRadius(DS.corner)
    }
}

/// Bridges a `UIVisualEffectView` into SwiftUI to create blurred
/// backgrounds.  Can be used where a translucent glass effect is
/// desired.
struct VisualEffectBlur: UIViewRepresentable {
    var blurStyle: UIBlurEffect.Style = .systemUltraThinMaterial
    func makeUIView(context: Context) -> UIVisualEffectView {
        UIVisualEffectView(effect: UIBlurEffect(style: blurStyle))
    }
    func updateUIView(_ uiView: UIVisualEffectView, context: Context) {
        uiView.effect = UIBlurEffect(style: blurStyle)
    }
}
