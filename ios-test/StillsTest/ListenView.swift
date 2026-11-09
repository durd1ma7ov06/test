import SwiftUI

/// ListenView - Foydalanuvchi "Listen" tugmasini bosganda bildirishnoma orqali ochiladigan asosiy ekran.
/// Bu yerda foydalanuvchi qisqa audio/meditatsiya tinglab, qo'shimcha vaqt bonusiga ega bo'ladi.
struct ListenView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var audioPlayer = CalmAudioPlayer.shared

    @State private var progress: Double = 0.0
    @State private var isCompleted = false
    @State private var timerActive = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 28) {
                Spacer()

                // Audio belgisi va animatsiya
                ZStack {
                    Circle()
                        .fill(Color.blue.opacity(0.12))
                        .frame(width: 150, height: 150)

                    Image(systemName: audioPlayer.isPlaying ? "waveform" : "headphones")
                        .font(.system(size: 64))
                        .foregroundColor(.blue)
                        .symbolEffect(.pulse, isActive: audioPlayer.isPlaying)
                }

                VStack(spacing: 12) {
                    Text("Diqqatni tiklash")
                        .font(.title.bold())

                    Text("Instagram va tanlangan ilovalar bloklandi.\nSokin garmonik to'lqinni (432 Hz) tinglang va 5 daqiqa bonusga ega bo'ling.")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 24)
                }

                // Progress bar (Audio tinglash jarayoni)
                VStack(spacing: 8) {
                    ProgressView(value: progress, total: 1.0)
                        .tint(.blue)
                        .padding(.horizontal, 40)

                    Text(isCompleted ? "Tinglash yakunlandi! 🎉" : (audioPlayer.isPlaying ? "Sokin ohang yangramoqda..." : "Tinglashga tayyor"))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Spacer()

                // Tugmalar
                VStack(spacing: 14) {
                    if !isCompleted {
                        Button(action: togglePlay) {
                            HStack {
                                Image(systemName: audioPlayer.isPlaying ? "pause.fill" : "play.fill")
                                Text(audioPlayer.isPlaying ? "To'xtatib turish" : "Audioni boshlash (432 Hz)")
                            }
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(14)
                        }
                        .padding(.horizontal, 24)
                    } else {
                        Button(action: claimBonusTime) {
                            HStack {
                                Image(systemName: "gift.fill")
                                Text("5 daqiqa bonusni olish va ochish")
                            }
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.green)
                            .foregroundColor(.white)
                            .cornerRadius(14)
                        }
                        .padding(.horizontal, 24)
                    }

                    Button("Yopish") {
                        audioPlayer.stopCalmSound()
                        dismiss()
                    }
                    .foregroundColor(.secondary)
                }
                .padding(.bottom, 24)
            }
            .navigationTitle("Stills Audio")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Yopish") {
                        audioPlayer.stopCalmSound()
                        dismiss()
                    }
                }
            }
            .onDisappear {
                audioPlayer.stopCalmSound()
            }
        }
    }

    private func togglePlay() {
        if audioPlayer.isPlaying {
            audioPlayer.stopCalmSound()
        } else {
            audioPlayer.startCalmSound()
            startSimulationTimer()
        }
    }

    private func startSimulationTimer() {
        guard !timerActive else { return }
        timerActive = true

        Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { timer in
            if !audioPlayer.isPlaying {
                timer.invalidate()
                timerActive = false
                return
            }

            if progress < 1.0 {
                progress += 0.02 // Taxminan 5 soniyada to'liq to'ladi (test uchun juda qulay)
            } else {
                timer.invalidate()
                timerActive = false
                audioPlayer.stopCalmSound()
                isCompleted = true
            }
        }
    }

    private func claimBonusTime() {
        audioPlayer.stopCalmSound()
        // Bloklash ekranini vaqtincha olib tashlash va 5 daqiqaga yangi monitoring boshlash
        Monitoring.removeShield()
        try? Monitoring.start(minutes: 5)
        dismiss()
    }
}
