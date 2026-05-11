import SwiftUI

@main
struct KeymapOverlayApp: App {
    @State private var hidMonitor = HIDKeyboardMonitor()
    @State private var overlayManager: OverlayManager

    init() {
        let monitor = HIDKeyboardMonitor()
        _hidMonitor = State(initialValue: monitor)
        _overlayManager = State(initialValue: OverlayManager(hidMonitor: monitor))
        monitor.start()
    }

    var body: some Scene {
        MenuBarExtra("KO", systemImage: "keyboard") {
            Button(overlayManager.isVisible ? "Hide Overlay" : "Show Overlay") {
                overlayManager.toggle()
            }
            .keyboardShortcut("k", modifiers: [.command, .shift])

            Text(hidMonitor.isDeviceConnected ? "Keyboard: Connected" : "Keyboard: Disconnected")
                .foregroundStyle(hidMonitor.isDeviceConnected ? .primary : .secondary)

            Divider()

            Button("Quit") {
                NSApplication.shared.terminate(nil)
            }
            .keyboardShortcut("q")
        }
    }
}
