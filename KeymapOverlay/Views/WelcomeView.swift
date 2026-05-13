import SwiftUI

struct WelcomeView: View {
    var keymapManager: KeymapManager
    @Bindable private var settings = AppSettings.shared

    @State private var openAtLogin = true
    @State private var selectedFilePath: String?
    @State private var parseError: String?
    @State private var layerNames: [String] = []

    var body: some View {
        VStack(spacing: 0) {
            Spacer().frame(height: 48)

            Image(nsImage: NSApplication.shared.applicationIconImage)
                .resizable()
                .frame(width: 128, height: 128)

            Spacer().frame(height: 24)

            Text("Welcome to KeymapOverlay")
                .font(.largeTitle.bold())

            Spacer().frame(height: 8)

            Text("Display your ZMK keyboard layers as a floating overlay.")
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            Spacer().frame(height: 36)

            // MARK: File Picker

            VStack(alignment: .leading, spacing: 10) {
                Text("Keymap File")
                    .font(.headline)

                HStack(spacing: 12) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 8)
                            .fill(.quaternary)

                        if let path = selectedFilePath {
                            Text(URL(fileURLWithPath: path).lastPathComponent)
                                .font(.body.monospaced())
                                .lineLimit(1)
                                .truncationMode(.middle)
                                .padding(.horizontal, 12)
                        } else {
                            Text("No file selected")
                                .foregroundStyle(.tertiary)
                        }
                    }
                    .frame(height: 36)

                    Button("Browse...") {
                        let panel = NSOpenPanel()
                        panel.allowsMultipleSelection = false
                        if panel.runModal() == .OK, let url = panel.url {
                            let path = url.path(percentEncoded: false)
                            selectedFilePath = path
                            keymapManager.parseAndStore(filePath: path)
                            if let error = keymapManager.parseError {
                                parseError = error
                                layerNames = []
                            } else {
                                parseError = nil
                                layerNames = keymapManager.layerNames
                            }
                        }
                    }
                }

                if let error = parseError {
                    Text(error)
                        .foregroundStyle(.red)
                        .font(.caption)
                } else if !layerNames.isEmpty {
                    HStack(spacing: 4) {
                        Text("Layers:")
                            .foregroundStyle(.secondary)
                        Text(layerNames.joined(separator: ", "))
                    }
                    .font(.caption)
                }

                Text("You can also set this later in Settings.")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            Spacer().frame(height: 28)

            // MARK: Open at Login

            Toggle("Open at Login", isOn: $openAtLogin)
                .frame(maxWidth: .infinity, alignment: .leading)

            Spacer().frame(height: 36)

            // MARK: Get Started

            Button {
                completeOnboarding()
            } label: {
                Text("Get Started")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)

            Spacer().frame(height: 48)
        }
        .padding(.horizontal, 48)
        .frame(width: 500)
        .fixedSize()
    }

    private func completeOnboarding() {
        settings.openAtLogin = openAtLogin

        if let path = selectedFilePath {
            settings.configFilePath = path
            keymapManager.parseAndStore(filePath: path)
            keymapManager.startWatchingFile(path)
        }

        UserDefaults.standard.set(true, forKey: "hasLaunchedBefore")
        UserDefaults.standard.set(true, forKey: "hasCompletedOnboarding")

        NSApplication.shared.keyWindow?.close()
    }
}
