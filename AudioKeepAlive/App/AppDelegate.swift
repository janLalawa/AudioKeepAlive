import Cocoa

class AppDelegate: NSObject, NSApplicationDelegate {
    private var menuBarManager: MenuBarManager!
    private var audioService: AudioService!
    private var launchAtLoginService: LaunchAtLoginService!
    private var audioMonitorService: AudioMonitorService!

    func applicationDidFinishLaunching(_ notification: Notification) {
        print("=== App launched ===")

        audioService = AudioService()
        launchAtLoginService = LaunchAtLoginService()
        audioMonitorService = AudioMonitorService()

        audioMonitorService.onAudioActivityChanged = { [weak self] hasActivity in
            if hasActivity {
                self?.audioService.autoResume()
            } else {
                self?.audioService.autoPause()
            }
        }

        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.menuBarManager = MenuBarManager(
                audioService: self.audioService,
                launchAtLoginService: self.launchAtLoginService,
                audioMonitorService: self.audioMonitorService
            )

            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak self] in
                self?.audioService.start()

                self?.menuBarManager.refreshMenuState()

                if self?.audioMonitorService.isMonitoring ?? false {
                    self?.audioMonitorService.startMonitoring()
                }

                print("=== Setup complete ===")
            }
        }
    }

    func applicationWillTerminate(_ notification: Notification) {
        audioMonitorService.stopMonitoring()
        audioService.stop()
    }
}
