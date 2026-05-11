import SwiftUI
import SwiftData

@main
struct KeymapOverlayApp: App {
    @State private var hidMonitor: HIDKeyboardMonitor
    @State private var overlayManager: OverlayManager
    @State private var keymapManager: KeymapManager

    let modelContainer: ModelContainer

    init() {
        let schema = Schema([Keymap.self, Layer.self, LayerBinding.self])
        let container = try! ModelContainer(for: schema)

        let monitor = HIDKeyboardMonitor()
        let kmManager = KeymapManager(modelContainer: container)

        self.modelContainer = container
        _hidMonitor = State(initialValue: monitor)
        _keymapManager = State(initialValue: kmManager)
        _overlayManager = State(initialValue: OverlayManager(hidMonitor: monitor, keymapManager: kmManager))

        monitor.start()
        kmManager.loadFromPersistence()

        let path = AppSettings.shared.configFilePath
        if !path.isEmpty {
            kmManager.parseAndStore(filePath: path)
            kmManager.startWatchingFile(path)
        }
    }

    @Environment(\.openSettings) private var openSettings

    var body: some Scene {
        MenuBarExtra("KO", systemImage: "keyboard") {
            Button(overlayManager.isVisible ? "Hide Overlay" : "Show Overlay") {
                overlayManager.toggle()
            }
            .keyboardShortcut("k", modifiers: [.command, .shift])

            Text(hidMonitor.isDeviceConnected ? "Keyboard: Connected" : "Keyboard: Disconnected")
                .foregroundStyle(hidMonitor.isDeviceConnected ? .primary : .secondary)

            Divider()

            Button("Settings...") {
                openSettings()
                NSApplication.shared.activate()
            }
            .keyboardShortcut(",")

            Button("Quit") {
                NSApplication.shared.terminate(nil)
            }
            .keyboardShortcut("q")
        }

        Settings {
            SettingsView(keymapManager: keymapManager)
        }
    }
}
