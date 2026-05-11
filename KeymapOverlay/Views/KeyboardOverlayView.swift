import SwiftUI
import SwiftData

struct KeyboardOverlayView: View {
    var keymapManager: KeymapManager
    var onDismiss: (() -> Void)?

    var body: some View {
        HStack(spacing: KeyboardMetrics.halfGap) {
            KeyboardHalfView(half: .left, keys: keymapManager.currentKeys)
            KeyboardHalfView(half: .right, keys: keymapManager.currentKeys)
        }
        .padding(KeyboardMetrics.overlayPadding)
        .glassEffect(.clear, in: RoundedRectangle(cornerRadius: KeyboardMetrics.overlayCornerRadius))
        .onTapGesture {
            onDismiss?()
        }
    }
}

#Preview {
    let container = try! ModelContainer(for: Keymap.self, Layer.self, LayerBinding.self)
    KeyboardOverlayView(keymapManager: KeymapManager(modelContainer: container))
        .padding(40)
}
