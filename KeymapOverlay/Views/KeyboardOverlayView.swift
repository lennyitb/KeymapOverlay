import SwiftUI

struct KeyboardOverlayView: View {
    var onDismiss: (() -> Void)?

    var body: some View {
        HStack(spacing: KeyboardMetrics.halfGap) {
            KeyboardHalfView(half: .left)
            KeyboardHalfView(half: .right)
        }
        .padding(KeyboardMetrics.overlayPadding)
        .glassEffect(.clear, in: RoundedRectangle(cornerRadius: KeyboardMetrics.overlayCornerRadius))
        .onTapGesture {
            onDismiss?()
        }
    }
}

#Preview {
    KeyboardOverlayView()
        .padding(40)
}
