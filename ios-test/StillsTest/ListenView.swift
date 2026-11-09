import SwiftUI

/// ListenView - Foydalanuvchi "Listen" tugmasini bosganda bildirishnoma orqali ochiladigan asosiy ekran.
/// Bu yerda foydalanuvchi qisqa audio/meditatsiya tinglab, qo'shimcha vaqt bonusiga ega bo'ladi.
struct ListenView: View {
    @Environment(\.dismiss) private var dismiss

    @State private var isPlaying = false
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
                        .frame(width: 140, height: 140)

                    Image(systemName: isPlaying ? "waveform" : "headphones")
                        .font(.system(size: 60))
                        .foregroundColor(.blue)
                        .symbolEffect(.pulse, isActive: isPlaying)
                }

                VStack(spacing: 10) {
                    Text("Diqqatni tiklash")
                        .font(.title.bold())

                    Text("Instagram/Ilovalar bloklandi. 1 daqiqa tinchlanish audiosini tinglang va 5 daqiqa bonusga ega bo'ling.")
                        .font(.body)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 24)
                }

                // Progress bar (Audio tinglash jarayoni)
                VStack(spacing: 8) {
                    ProgressView(value: progress, total: 1.0)
                        .tint(.blue)
                        .padding(.horizontal, 40)

                    Text(isCompleted ? "Tinglash yakunlandi! 🎉" : (isPlaying ? "Tinglanmoqda..." : "Tinglashga tayyor"))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Spacer()

                // Tugmalar
                VStack(spacing: 14) {
                    if !isCompleted {
                        Button(action: togglePlay) {
                            HStack {
                                Image(systemName: isPlaying ? "pause.fill" : "play.fill")
                                Text(isPlaying ? "To'xtatib turish" : "Audioni boshlash (1 daqiqa)")
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(12)
                        }
                        .padding(.horizontal, 24)
                    } else {
                        Button(action: claimBonusTime) {
                            HStack {
                                Image(systemName: "gift.fill")
                                Text("5 daqiqa bonusni olish va ochish")
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.green)
                            .foregroundColor(.white)
                            .cornerRadius(12)
                        }
                        .padding(.horizontal, 24)
                    }

                    Button("Yopish") {
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
                    Button("Yopish") { dismiss() }
                }
            }
        }
    }

    private func togglePlay() {
        isPlaying.toggle()
        if isPlaying {
            startSimulationTimer()
        }
    }

    private func startSimulationTimer() {
        guard !timerActive else { return }
        timerActive = true

        Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { timer in
            if !isPlaying {
                timer.invalidate()
                timerActive = false
                return
            }

            if progress < 1.0 {
                progress += 0.02 // Taxminan 5 soniyada to'liq to'ladi (test uchun qulay)
            } else {
                timer.invalidate()
                timerActive = false
                isPlaying = false
                isCompleted = true
            }
        }
    }

    private func claimBonusTime() {
        // Bloklash ekranini vaqtincha olib tashlash va 5 daqiqaga yangi monitoring boshlash
        Monitoring.removeShield()
        try? Monitoring.start(minutes: 5)
        dismiss()
    }
}
