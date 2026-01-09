import Foundation
import AVFoundation

class AudioService {
    private var audioEngine: AVAudioEngine!
    private var playerNode: AVAudioPlayerNode!
    private(set) var isPlaying = false
    private var isAutoPaused = false
    private(set) var isManuallyStoppedByUser = false

    var onStatusChanged: ((String) -> Void)?

    init() {
        setupAudioEngine()
    }

    private func setupAudioEngine() {
        audioEngine = AVAudioEngine()
        playerNode = AVAudioPlayerNode()

        audioEngine.attach(playerNode)

        let format = AVAudioFormat(standardFormatWithSampleRate: 44100, channels: 2)!
        audioEngine.connect(playerNode, to: audioEngine.mainMixerNode, format: format)

        audioEngine.mainMixerNode.outputVolume = 0

        print("Audio engine configured")
    }

    func start() {
        guard !isPlaying else { return }

        isManuallyStoppedByUser = false
        isAutoPaused = false

        do {
            try audioEngine.start()
            print("Audio engine started")
        } catch {
            print("Failed to start audio engine: \(error)")
            onStatusChanged?("Error: \(error.localizedDescription)")
            return
        }

        scheduleBuffer()
        playerNode.play()

        isPlaying = true
        onStatusChanged?("Playing (keeping audio active)")
        print("Silent audio playback started")
    }

    func stop() {
        guard isPlaying else { return }

        playerNode.stop()
        audioEngine.stop()

        isPlaying = false
        isManuallyStoppedByUser = true
        isAutoPaused = false
        onStatusChanged?("Stopped")
        print("Playback stopped")
    }

    func autoPause() {
        guard isPlaying, !isManuallyStoppedByUser else { return }

        playerNode.stop()
        audioEngine.stop()

        isPlaying = false
        isAutoPaused = true
        onStatusChanged?("Auto-paused (no audio activity)")
        print("Auto-paused due to inactivity")
    }

    func autoResume() {
        // Only auto-resume if we were auto-paused (not manually stopped)
        guard !isPlaying, isAutoPaused, !isManuallyStoppedByUser else { return }

        start()
        print("Auto-resumed due to audio activity")
    }

    func toggle() {
        if isPlaying {
            stop()
        } else {
            start()
        }
    }

    private func scheduleBuffer() {
        let format = AVAudioFormat(standardFormatWithSampleRate: 44100, channels: 2)!
        let frameCount = AVAudioFrameCount(44100)

        guard let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frameCount) else {
            print("Failed to create buffer")
            return
        }

        buffer.frameLength = frameCount

        if let data = buffer.floatChannelData {
            for channel in 0..<Int(format.channelCount) {
                memset(data[channel], 0, Int(frameCount) * MemoryLayout<Float>.size)
            }
        }

        playerNode.scheduleBuffer(buffer, at: nil, options: .loops)
    }
}
