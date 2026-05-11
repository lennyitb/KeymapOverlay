import AppKit
import ObjectiveC.runtime

class OverlayPanel: NSPanel {
    init(contentRect: NSRect) {
        _ = Self.installGlassWorkaround

        super.init(
            contentRect: contentRect,
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )

        isOpaque = false
        backgroundColor = .clear
        level = .floating
        hasShadow = false
        ignoresMouseEvents = false
        collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .stationary]
        isReleasedWhenClosed = false
    }

    override var canBecomeKey: Bool { false }
    override var canBecomeMain: Bool { false }

    // FB21375029: liquid glass degrades to flat blur on non-key windows.
    // Swizzle _hasActiveAppearance to return true so glass renders correctly
    // without actually stealing keyboard focus.
    private static let installGlassWorkaround: Void = {
        let selector = NSSelectorFromString("_hasActiveAppearance")
        guard let original = class_getInstanceMethod(OverlayPanel.self, selector),
              let replacement = class_getInstanceMethod(OverlayPanel.self, #selector(alwaysActiveAppearance))
        else { return }
        method_exchangeImplementations(original, replacement)
    }()

    @objc private func alwaysActiveAppearance() -> Bool { true }
}
