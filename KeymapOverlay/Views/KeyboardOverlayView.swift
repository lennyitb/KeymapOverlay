import SwiftUI

struct KeyboardOverlayView: View {
    var onDismiss: (() -> Void)?

    var body: some View {
        HStack(spacing: KeyboardMetrics.halfGap) {
            KeyboardHalfView(half: .left)
            KeyboardHalfView(half: .right)
        }
        .padding(KeyboardMetrics.overlayPadding)
        .background {
            RoundedRectangle(cornerRadius: KeyboardMetrics.overlayCornerRadius)
                .fill(.ultraThinMaterial)
        }
        .onTapGesture {
            onDismiss?()
        }
    }
}

#Preview {
    KeyboardOverlayView()
        .padding(40)
}
