import Foundation
import ServiceManagement

class LaunchAtLoginService {
    private let launchAtLoginKey = "launchAtLogin"

    var isEnabled: Bool {
        get {
            UserDefaults.standard.bool(forKey: launchAtLoginKey)
        }
        set {
            UserDefaults.standard.set(newValue, forKey: launchAtLoginKey)
            updateLaunchAtLogin(enabled: newValue)
        }
    }

    init() {
        if isEnabled {
            updateLaunchAtLogin(enabled: true)
        }
    }

    private func updateLaunchAtLogin(enabled: Bool) {
        if #available(macOS 13.0, *) {
            do {
                if enabled {
                    try SMAppService.mainApp.register()
                    print("Registered for launch at login")
                } else {
                    try SMAppService.mainApp.unregister()
                    print("Unregistered from launch at login")
                }
            } catch {
                print("Failed to \(enabled ? "enable" : "disable") launch at login: \(error)")
            }
        } else {
            #if !DEBUG
            SMLoginItemSetEnabled(Bundle.main.bundleIdentifier! as CFString, enabled)
            #else
            print("Launch at login not available in debug mode on macOS < 13")
            #endif
        }
    }

    func toggle() {
        isEnabled.toggle()
    }
}
