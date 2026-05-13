import SwiftUI

struct SettingsView: View {
    @Bindable var settings = AppSettings.shared
    var keymapManager: KeymapManager
    var updaterManager: UpdaterManager
    @State private var showAbout = false

    var body: some View {
        Form {
            Section("Keyboard Config") {
                LabeledContent("File path") {
                    HStack {
                        TextField("", text: $settings.configFilePath)
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

                HStack {
                    Text("Scale")
                    Slider(value: $settings.overlayScale, in: 0.5...2.0, step: 0.1)
                    Text("\(settings.overlayScale, specifier: "%.1f")x")
                        .monospacedDigit()
                        .frame(width: 32, alignment: .trailing)
                }
            }
            Section("General") {
                Toggle("Open at Login", isOn: $settings.openAtLogin)
                Toggle("Automatically check for updates", isOn: Binding(
                    get: { updaterManager.automaticallyChecksForUpdates },
                    set: { updaterManager.automaticallyChecksForUpdates = $0 }
                ))
                Button("Check for Updates...") {
                    updaterManager.checkForUpdates()
                }
            }

            Section {
                Button("About KeymapOverlay...") {
                    showAbout = true
                }
            }
        }
        .formStyle(.grouped)
        .frame(width: 580)
        .fixedSize()
        .sheet(isPresented: $showAbout) {
            AboutView()
        }
    }

    private func loadConfigFile() {
        let path = settings.configFilePath
        guard !path.isEmpty else { return }
        keymapManager.parseAndStore(filePath: path)
        keymapManager.startWatchingFile(path)
    }
}

struct AboutView: View {
    @Environment(\.dismiss) private var dismiss

    private var version: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "1.0"
    }

    private var build: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "1"
    }

    var body: some View {
        VStack(spacing: 16) {
            Image(nsImage: NSApplication.shared.applicationIconImage)
                .resizable()
                .frame(width: 64, height: 64)

            Text("KeymapOverlay")
                .font(.title2.bold())

            Text("Version \(version) (\(build))")
                .foregroundStyle(.secondary)
                .font(.callout)

            Text("Made by Lenny Phelan")
                .font(.callout)

            Text("lenny@lenny.zone")
                .font(.callout)
                .foregroundStyle(.secondary)

            Button("OK") {
                dismiss()
            }
            .keyboardShortcut(.defaultAction)
        }
        .padding(32)
        .frame(width: 280)
    }
}
