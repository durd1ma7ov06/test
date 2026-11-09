import SwiftUI

/// Placeholder. In the real app, the notification opens the Stills section instead.
struct ListenView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var earned = false

    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "headphones").font(.system(size: 56))
            Text("Listen").font(.largeTitle.bold())
            Text("It worked: the notification opened the app.\nIn the real app, the Stills section opens here.")
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)

            Button(earned ? "Unblocked for 5 minutes" : "I listened → give me 5 minutes") {
                Monitoring.removeShield()
                try? Monitoring.start(minutes: 5)
                earned = true
            }
            .buttonStyle(.borderedProminent)
            .disabled(earned)

            Button("Close") { dismiss() }
        }
        .padding()
    }
}
