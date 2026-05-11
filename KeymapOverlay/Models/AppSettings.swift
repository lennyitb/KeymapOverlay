import Foundation

@Observable
class AppSettings {
    static let shared = AppSettings()

    var configFilePath: String {
        didSet { UserDefaults.standard.set(configFilePath, forKey: "configFilePath") }
    }

    var showDelaySeconds: Double {
        didSet { UserDefaults.standard.set(showDelaySeconds, forKey: "showDelaySeconds") }
    }

    var overlayScale: Double {
        didSet { UserDefaults.standard.set(overlayScale, forKey: "overlayScale") }
    }

    private init() {
        self.configFilePath = UserDefaults.standard.string(forKey: "configFilePath") ?? ""
        self.showDelaySeconds = UserDefaults.standard.object(forKey: "showDelaySeconds") != nil
            ? UserDefaults.standard.double(forKey: "showDelaySeconds")
            : 0
        self.overlayScale = UserDefaults.standard.object(forKey: "overlayScale") != nil
            ? UserDefaults.standard.double(forKey: "overlayScale")
            : 1.0
    }
}
