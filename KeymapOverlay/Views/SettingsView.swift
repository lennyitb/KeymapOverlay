import SwiftUI

struct SettingsView: View {
    @Bindable var settings = AppSettings.shared
    var keymapManager: KeymapManager

    var body: some View {
        Form {
            Section("Keyboard Config") {
                HStack {
                    TextField("File path", text: $settings.configFilePath)
                        .textFieldStyle(.roundedBorder)
                        .onSubmit {
                            loadConfigFile()
                        }

                    Button("Browse...") {
                        let panel = NSOpenPanel()
                        panel.allowsMultipleSelection = false
                        if panel.runModal() == .OK, let url = panel.url {
                            settings.configFilePath = url.path(percentEncoded: false)
                            loadConfigFile()
                        }
                    }
                }

                if let error = keymapManager.parseError {
                    Text(error)
                        .foregroundStyle(.red)
                        .font(.caption)
                } else if !keymapManager.layerNames.isEmpty {
                    HStack {
                        Text("Layers:")
                            .foregroundStyle(.secondary)
                        Text(keymapManager.layerNames.joined(separator: ", "))
                    }
                    .font(.caption)
                }
            }

            Section("Overlay") {
                HStack {
                    Text("Show delay")
                    Slider(value: $settings.showDelaySeconds, in: 0...2, step: 0.1)
                    Text("\(settings.showDelaySeconds, specifier: "%.1f")s")
                        .monospacedDigit()
                        .frame(width: 32, alignment: .trailing)
                }
            }
        }
        .formStyle(.grouped)
        .frame(width: 420)
        .fixedSize()
    }

    private func loadConfigFile() {
        let path = settings.configFilePath
        guard !path.isEmpty else { return }
        keymapManager.parseAndStore(filePath: path)
        keymapManager.startWatchingFile(path)
    }
}
