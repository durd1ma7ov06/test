import Foundation
import AVFoundation

/// Tinchlantiruvchi audio generatori (Hech qanday og'ir mp3 fayllarsiz, toza audio sintezi)
@MainActor
final class CalmAudioPlayer: ObservableObject {
    static let shared = CalmAudioPlayer()

    @Published var isPlaying: Bool = false

    private var audioEngine: AVAudioEngine?
    private var playerNode: AVAudioPlayerNode?

    init() {}

    func startCalmSound() {
        guard !isPlaying else { return }

        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.playback, mode: .default, options: [.mixWithOthers])
            try session.setActive(true)

            let engine = AVAudioEngine()
            let player = AVAudioPlayerNode()

            let sampleRate: Double = 44100.0
            guard let format = AVAudioFormat(standardFormatWithSampleRate: sampleRate, channels: 1) else { return }

            // 3 soniyalik sokin 432Hz garmonik to'lqin hosil qilish va tsiklda aylantirish
            let durationSeconds = 3.0
            let frameCount = AVAudioFrameCount(sampleRate * durationSeconds)
            guard let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frameCount) else { return }
            buffer.frameLength = frameCount

            let floatData = buffer.floatChannelData![0]
            let frequency: Double = 432.0 // Tinchlantiruvchi chastota

            for i in 0..<Int(frameCount) {
                let time = Double(i) / sampleRate
                // Asosiy to'lqin va yumshoq tebranish
                let sine = sin(2.0 * .pi * frequency * time)
                let gentleHarmonic = 0.25 * sin(2.0 * .pi * (frequency * 1.5) * time)
                // Yumshoq nafas olish (fade in / out) effekti
                let envelope = 0.5 * (1.0 - cos(2.0 * .pi * time / durationSeconds))
                floatData[i] = Float((sine + gentleHarmonic) * envelope * 0.15)
            }

            engine.attach(player)
            engine.connect(player, to: engine.mainMixerNode, format: format)
            try engine.start()

            player.play()
            player.scheduleBuffer(buffer, at: nil, options: .loops, completionHandler: nil)

            self.audioEngine = engine
            self.playerNode = player
            self.isPlaying = true
        } catch {
            print("Audio sintezatorini ishga tushirishda xatolik: \(error.localizedDescription)")
        }
    }

    func stopCalmSound() {
        guard isPlaying else { return }
        playerNode?.stop()
        audioEngine?.stop()
        audioEngine = nil
        playerNode = nil
        isPlaying = false

        try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
    }
}
