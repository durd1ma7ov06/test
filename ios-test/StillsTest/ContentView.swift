import SwiftUI
import FamilyControls
import ManagedSettings
import UserNotifications

struct ContentView: View {
    @ObservedObject private var router = Router.shared

    @State private var selection = Shared.loadSelection()
    @State private var showPicker = false
    @State private var minutes = 2
    @State private var status = "Not started"

    @State private var denyDeletion =
        ManagedSettingsStore(named: .strict).application.denyAppRemoval ?? false
    @State private var lockDateTime =
        ManagedSettingsStore(named: .strict).dateAndTime.requireAutomaticDateAndTime ?? false

    var body: some View {
        NavigationStack {
            Form {
                Section("1 · Permissions") {
                    Button("Allow Screen Time + notifications") {
                        Task { await requestPermissions() }
                    }
                }

                Section("2 · Choose apps") {
                    Button("Choose apps to limit") { showPicker = true }
                    Text("\(selection.applicationTokens.count) apps · \(selection.categoryTokens.count) categories · \(selection.webDomainTokens.count) websites")
                        .font(.footnote)
                    ForEach(Array(selection.applicationTokens), id: \.self) { token in
                        Label(token)
                    }
                }

                Section("3 · Set the limit") {
                    Stepper("Limit: \(minutes) min", value: $minutes, in: 1...60)
                    Button("Start limit") { startLimit() }
                    Button("Stop + unblock", role: .destructive) {
                        Monitoring.stop()
                        status = "Stopped. Nothing is blocked."
                    }
                    Text(status).font(.footnote)
                }

                Section("4 · Quick test (no waiting)") {
                    Button("Block now") {
                        Monitoring.applyShield()
                        status = "Blocked now. Open a chosen app and tap Listen."
                    }
                }

                Section {
                    Toggle("Prevent deleting apps", isOn: $denyDeletion)
                        .onChange(of: denyDeletion) { _, on in
                            ManagedSettingsStore(named: .strict).application.denyAppRemoval = on ? true : nil
                        }
                    Toggle("Lock date & time to automatic", isOn: $lockDateTime)
                        .onChange(of: lockDateTime) { _, on in
                            ManagedSettingsStore(named: .strict).dateAndTime.requireAutomaticDateAndTime = on ? true : nil
                        }
                    Button("Reset everything", role: .destructive) { resetEverything() }
                } header: {
                    Text("5 · Hardening tests")
                } footer: {
                    Text("Tap Reset everything before you delete this app.")
                }
            }
            .navigationTitle("Stills test")
            .familyActivityPicker(isPresented: $showPicker, selection: $selection)
            .onChange(of: selection) { _, newValue in
                Shared.saveSelection(newValue)
                status = "Apps saved. Tap Start limit again to use the new selection."
            }
            .sheet(isPresented: $router.showListen) {
                ListenView()
            }
        }
    }

    private func requestPermissions() async {
        do {
            try await AuthorizationCenter.shared.requestAuthorization(for: .individual)
            let granted = try await UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge])
            if granted {
                status = "Permissions granted (Screen Time + Notifications)."
            } else {
                status = "Screen Time allowed, but notifications were denied. Please enable notifications in iOS Settings."
            }
        } catch {
            status = "Permission error: \(error.localizedDescription)"
        }
    }

    private func startLimit() {
        guard !selection.applicationTokens.isEmpty || !selection.categoryTokens.isEmpty || !selection.webDomainTokens.isEmpty else {
            status = "Choose apps first."
            return
        }
        do {
            try Monitoring.start(minutes: minutes)
            status = "Limit started: \(minutes) min. Now go use a chosen app."
        } catch {
            status = "Couldn't start: \(error.localizedDescription)"
        }
    }

    private func resetEverything() {
        Monitoring.stop()
        ManagedSettingsStore(named: .strict).clearAllSettings()
        denyDeletion = false
        lockDateTime = false
        status = "Everything reset."
    }
}
