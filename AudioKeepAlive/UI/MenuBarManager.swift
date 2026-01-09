import Cocoa

class MenuBarManager {
    private var statusItem: NSStatusItem!
    private let audioService: AudioService
    private let launchAtLoginService: LaunchAtLoginService
    private let audioMonitorService: AudioMonitorService

    init(audioService: AudioService,
         launchAtLoginService: LaunchAtLoginService,
         audioMonitorService: AudioMonitorService) {
        self.audioService = audioService
        self.launchAtLoginService = launchAtLoginService
        self.audioMonitorService = audioMonitorService

        setupStatusItem()
        setupAudioServiceCallbacks()
    }

    private func setupStatusItem() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)

        if let button = statusItem.button {
            button.image = NSImage(systemSymbolName: "speaker.wave.2.fill",
                                  accessibilityDescription: "Audio Keep-Alive")
            button.image?.isTemplate = true
        }

        buildMenu()
    }

    private func buildMenu() {
        let menu = NSMenu()

        let toggleItem = NSMenuItem(
            title: audioService.isPlaying ? "Stop" : "Start",
            action: #selector(togglePlayback),
            keyEquivalent: ""
        )
        toggleItem.target = self
        toggleItem.tag = MenuItemTag.toggle.rawValue
        menu.addItem(toggleItem)

        menu.addItem(.separator())

        let statusMenuItem = NSMenuItem(title: "Status: Starting...", action: nil, keyEquivalent: "")
        statusMenuItem.tag = MenuItemTag.status.rawValue
        menu.addItem(statusMenuItem)

        menu.addItem(.separator())

        let smartPauseItem = NSMenuItem(
            title: "Smart Pause (1hr inactivity)",
            action: #selector(toggleSmartPause),
            keyEquivalent: ""
        )
        smartPauseItem.target = self
        smartPauseItem.state = audioMonitorService.isMonitoring ? .on : .off
        smartPauseItem.tag = MenuItemTag.smartPause.rawValue
        menu.addItem(smartPauseItem)

        let launchItem = NSMenuItem(
            title: "Launch at Login",
            action: #selector(toggleLaunchAtLogin),
            keyEquivalent: ""
        )
        launchItem.target = self
        launchItem.state = launchAtLoginService.isEnabled ? .on : .off
        launchItem.tag = MenuItemTag.launchAtLogin.rawValue
        menu.addItem(launchItem)

        menu.addItem(.separator())

        let quitItem = NSMenuItem(
            title: "Quit",
            action: #selector(NSApplication.terminate(_:)),
            keyEquivalent: "q"
        )
        menu.addItem(quitItem)

        self.statusItem.menu = menu
    }

    private func setupAudioServiceCallbacks() {
        audioService.onStatusChanged = { [weak self] status in
            self?.updateStatus(status)
        }
    }

    func refreshMenuState() {
        updateToggleMenuTitle()
    }

    @objc private func togglePlayback() {
        audioService.toggle()
        updateToggleMenuTitle()
    }

    @objc private func toggleLaunchAtLogin() {
        launchAtLoginService.toggle()
        updateLaunchAtLoginMenuItem()
    }

    @objc private func toggleSmartPause() {
        if audioMonitorService.isMonitoring {
            audioMonitorService.stopMonitoring()
        } else {
            audioMonitorService.startMonitoring()
        }
        updateSmartPauseMenuItem()
    }

    private func updateToggleMenuTitle() {
        guard let menu = statusItem.menu,
              let item = menu.item(withTag: MenuItemTag.toggle.rawValue) else { return }
        item.title = audioService.isPlaying ? "Stop" : "Start"
    }

    private func updateStatus(_ status: String) {
        guard let menu = statusItem.menu,
              let item = menu.item(withTag: MenuItemTag.status.rawValue) else { return }
        item.title = "Status: \(status)"
    }

    private func updateLaunchAtLoginMenuItem() {
        guard let menu = statusItem.menu,
              let item = menu.item(withTag: MenuItemTag.launchAtLogin.rawValue) else { return }
        item.state = launchAtLoginService.isEnabled ? .on : .off
    }

    private func updateSmartPauseMenuItem() {
        guard let menu = statusItem.menu,
              let item = menu.item(withTag: MenuItemTag.smartPause.rawValue) else { return }
        item.state = audioMonitorService.isMonitoring ? .on : .off
    }
}
