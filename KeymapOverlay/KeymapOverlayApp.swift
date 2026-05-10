import SwiftUI

@main
struct KeymapOverlayApp: App {
    @State private var overlayManager = OverlayManager()

    var body: some Scene {
        WindowGroup {
            Text("KeymapOverlay is running. Check your menu bar for the keyboard icon.")
                .padding()
                .frame(width: 400, height: 100)
        }

        MenuBarExtra("KO", systemImage: "keyboard") {
            Button(overlayManager.isVisible ? "Hide Overlay" : "Show Overlay") {
                overlayManager.toggle()
            }
            .keyboardShortcut("k", modifiers: [.command, .shift])

            Divider()

            Button("Quit") {
                NSApplication.shared.terminate(nil)
            }
            .keyboardShortcut("q")
        }
    }
}
