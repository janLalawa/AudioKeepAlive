import Foundation
import AVFoundation
import CoreAudio

class AudioMonitorService {
    private var monitorTimer: Timer?
    private var lastAudioDetectedTime: Date?
    private let inactivityThreshold: TimeInterval = 3600
    private let checkInterval: TimeInterval = 60

    var onAudioActivityChanged: ((Bool) -> Void)?
    var isMonitoring = false

    private var hasRecentAudioActivity: Bool {
        guard let lastTime = lastAudioDetectedTime else { return false }
        return Date().timeIntervalSince(lastTime) < inactivityThreshold
    }

    func startMonitoring() {
        guard !isMonitoring else { return }

        isMonitoring = true
        lastAudioDetectedTime = Date()

        monitorTimer = Timer.scheduledTimer(withTimeInterval: checkInterval, repeats: true) { [weak self] _ in
            self?.checkAudioActivity()
        }

        print("Audio monitoring started")
    }

    func stopMonitoring() {
        monitorTimer?.invalidate()
        monitorTimer = nil
        isMonitoring = false
        print("Audio monitoring stopped")
    }

    private func checkAudioActivity() {
        let hasActivity = detectSystemAudioActivity()

        if hasActivity {
            let wasInactive = !hasRecentAudioActivity
            lastAudioDetectedTime = Date()

            if wasInactive {
                print("Audio activity detected - resuming keep-alive")
                onAudioActivityChanged?(true)
            }
        } else if !hasRecentAudioActivity {
            print("No audio activity for \(Int(inactivityThreshold/60)) minutes - pausing keep-alive")
            onAudioActivityChanged?(false)
        }
    }

    private func detectSystemAudioActivity() -> Bool {
        var propertyAddress = AudioObjectPropertyAddress(
            mSelector: kAudioHardwarePropertyDefaultOutputDevice,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMain
        )

        var deviceID: AudioDeviceID = 0
        var size = UInt32(MemoryLayout<AudioDeviceID>.size)

        let status = AudioObjectGetPropertyData(
            AudioObjectID(kAudioObjectSystemObject),
            &propertyAddress,
            0,
            nil,
            &size,
            &deviceID
        )

        guard status == noErr, deviceID != 0 else {
            return false
        }

        return isAudioDeviceActive(deviceID)
    }

    private func isAudioDeviceActive(_ deviceID: AudioDeviceID) -> Bool {
        var propertyAddress = AudioObjectPropertyAddress(
            mSelector: kAudioDevicePropertyDeviceIsRunningSomewhere,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMain
        )

        var isRunning: UInt32 = 0
        var size = UInt32(MemoryLayout<UInt32>.size)

        let status = AudioObjectGetPropertyData(
            deviceID,
            &propertyAddress,
            0,
            nil,
            &size,
            &isRunning
        )

        return status == noErr && isRunning != 0
    }

    func notifyAudioActive() {
        lastAudioDetectedTime = Date()
    }
}
