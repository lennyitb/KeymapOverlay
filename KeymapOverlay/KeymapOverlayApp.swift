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
        let config = ModelConfiguration(isStoredInMemoryOnly: false)
        let container: ModelContainer
        do {
            container = try ModelContainer(for: schema, configurations: config)
        } catch {
            let url = config.url
            let parent = url.deletingLastPathComponent()
            let name = url.lastPathComponent
            try? FileManager.default
                .contentsOfDirectory(atPath: parent.path)
                .filter { $0.hasPrefix(name) }
                .forEach { try? FileManager.default.removeItem(at: parent.appending(path: $0)) }
            container = try! ModelContainer(for: schema, configurations: config)
        }

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
        MenuBarExtra("KO", systemImage: "keyboard.badge.eye") {
            Text(hidMonitor.isDeviceConnected ? "Keyboard: Connected" : "Keyboard: Disconnected")
                .foregroundStyle(hidMonitor.isDeviceConnected ? .primary : .secondary)

            Divider()

            Button("Settings...") {
                openSettings()
                DispatchQueue.main.async {
                    NSApplication.shared.activate()
                    for window in NSApplication.shared.windows where window.canBecomeKey {
                        window.makeKeyAndOrderFront(nil)
                    }
                }
            }

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
