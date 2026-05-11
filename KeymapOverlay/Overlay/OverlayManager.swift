import AppKit
import SwiftUI

@Observable
class OverlayManager {
    var isVisible = false
    private(set) var isManualOverride = false

    private var panel: OverlayPanel?
    private let hidMonitor: HIDKeyboardMonitor

    init(hidMonitor: HIDKeyboardMonitor) {
        self.hidMonitor = hidMonitor
        hidMonitor.onStateChange = { [weak self] state in
            self?.handleHIDStateChange(state)
        }
    }

    func toggle() {
        isManualOverride = true
        if isVisible { hide() } else { show() }
    }

    func show() {
        if panel == nil {
            createPanel()
        }
        positionPanel()
        panel?.orderFrontRegardless()
        isVisible = true
    }

    func hide() {
        panel?.orderOut(nil)
        isVisible = false
    }

    private func handleHIDStateChange(_ state: KeyboardHIDState) {
        if !hidMonitor.isDeviceConnected {
            isManualOverride = false
        }

        guard !isManualOverride else { return }

        if state.isNonBaseLayerActive {
            show()
        } else {
            hide()
        }
    }

    private func createPanel() {
        let overlayView = KeyboardOverlayView(onDismiss: { [weak self] in
            self?.hide()
        })

        let hostingView = NSHostingView(rootView: overlayView)
        hostingView.setFrameSize(hostingView.fittingSize)

        let panel = OverlayPanel(contentRect: NSRect(origin: .zero, size: hostingView.fittingSize))
        panel.contentView = hostingView
        self.panel = panel
    }

    private func positionPanel() {
        guard let panel, let screen = NSScreen.main else { return }
        let screenFrame = screen.visibleFrame
        let panelSize = panel.frame.size
        let x = screenFrame.midX - panelSize.width / 2
        let y = screenFrame.midY - panelSize.height / 2
        panel.setFrameOrigin(NSPoint(x: x, y: y))
    }
}
