import SwiftUI
import FamilyControls
import ManagedSettings
import UserNotifications

struct ContentView: View {
    @ObservedObject private var router = Router.shared

    @State private var selection = Shared.loadSelection()
    @State private var showPicker = false
    @State private var minutes = 2
    @State private var statusMessage = "Tizim tayyor"
    @State private var isMonitoringActive = false

    @State private var denyDeletion =
        ManagedSettingsStore(named: .strict).application.denyAppRemoval ?? false
    @State private var lockDateTime =
        ManagedSettingsStore(named: .strict).dateAndTime.requireAutomaticDateAndTime ?? false

    var body: some View {
        NavigationStack {
            Form {
                // 1. Ruxsatlar bo'limi
                Section {
                    Button(action: {
                        Task { await requestPermissions() }
                    }) {
                        HStack {
                            Image(systemName: "checkmark.shield.fill")
                                .foregroundColor(.blue)
                            Text("Screen Time va Bildirishnomalarga ruxsat berish")
                        }
                    }
                } header: {
                    Text("1 · Ruxsatlar (Permissions)")
                } footer: {
                    Text("FamilyControls va mahalliy bildirishnomalar uchun ruxsat talab etiladi.")
                }

                // 2. Ilovalarni tanlash
                Section {
                    Button(action: { showPicker = true }) {
                        HStack {
                            Image(systemName: "apps.iphone")
                                .foregroundColor(.purple)
                            Text("Bloklanadigan ilovalarni tanlash")
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.footnote)
                                .foregroundColor(.secondary)
                        }
                    }

                    Text("\(selection.applicationTokens.count) ta ilova · \(selection.categoryTokens.count) ta toifa · \(selection.webDomainTokens.count) ta sayt tanlangan")
                        .font(.footnote)
                        .foregroundColor(.secondary)

                    if !selection.applicationTokens.isEmpty {
                        ForEach(Array(selection.applicationTokens), id: \.self) { token in
                            Label(token)
                        }
                    }
                } header: {
                    Text("2 · Cheklanadigan ilovalar")
                }

                // 3. Limit belgilash
                Section {
                    Stepper("Limit: \(minutes) daqiqa", value: $minutes, in: 1...60)

                    Button(action: startLimit) {
                        HStack {
                            Image(systemName: "play.circle.fill")
                                .foregroundColor(.green)
                            Text("Limitni boshlash (\(minutes) daqiqa)")
                        }
                    }

                    Button(role: .destructive, action: stopLimit) {
                        HStack {
                            Image(systemName: "stop.circle.fill")
                            Text("To'xtatish va blokni ochish")
                        }
                    }
                } header: {
                    Text("3 · Vaqt chegarasi")
                } footer: {
                    Text("Tanlangan ilovalar belgilangan daqiqa ishlatilgach, blokirovka ekrani chiqadi.")
                }

                // 4. Tezkor sinov (Kutmasdan tekshirish)
                Section {
                    Button(action: quickBlockTest) {
                        HStack {
                            Image(systemName: "bolt.shield.fill")
                                .foregroundColor(.orange)
                            Text("Hozir darhol bloklash (Sinov uchun)")
                        }
                    }
                } header: {
                    Text("4 · Tezkor sinov")
                } footer: {
                    Text("Vaqt o'tishini kutmasdan, bloklash ekrani va 'Listen' tugmasini darhol tekshirish.")
                }

                // 5. Kuchaytirilgan xavfsizlik sinovlari (Hardening)
                Section {
                    Toggle("Ilovalarni o'chirishni taqiqlash", isOn: $denyDeletion)
                        .onChange(of: denyDeletion) { _, on in
                            ManagedSettingsStore(named: .strict).application.denyAppRemoval = on ? true : nil
                        }

                    Toggle("Vaqtni avtomatik rejimga qulflash", isOn: $lockDateTime)
                        .onChange(of: lockDateTime) { _, on in
                            ManagedSettingsStore(named: .strict).dateAndTime.requireAutomaticDateAndTime = on ? true : nil
                        }

                    Button(role: .destructive, action: resetAll) {
                        HStack {
                            Image(systemName: "trash.fill")
                            Text("Barcha cheklovlarni to'liq tozalash")
                        }
                    }
                } header: {
                    Text("5 · Kuchaytirilgan sinovlar (Hardening)")
                } footer: {
                    Text("⚠️ DIQQAT: 'Ilovalarni o'chirishni taqiqlash' yoqilsa, butun telefondagi barcha ilovalarni o'chirish bloklanadi. Ilovani o'chirishdan oldin albatta 'To'liq tozalash' tugmasini bosing.")
                }

                // Status panel
                Section("Holat") {
                    Text(statusMessage)
                        .font(.footnote)
                        .foregroundColor(.secondary)
                }
            }
            .navigationTitle("Stills Fokus")
            .familyActivityPicker(isPresented: $showPicker, selection: $selection)
            .onChange(of: selection) { _, newValue in
                Shared.saveSelection(newValue)
                statusMessage = "Ilovalar saqlandi. Yangi ro'yxatni ishlatish uchun 'Limitni boshlash' tugmasini bosing."
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
                statusMessage = "Barcha ruxsatlar muvaffaqiyatli berildi."
            } else {
                statusMessage = "Screen Time ruxsat berildi, lekin bildirishnomalar rad etildi. Sozlamalardan yoqing."
            }
        } catch {
            statusMessage = "Ruxsat olishda xatolik: \(error.localizedDescription)"
        }
    }

    private func startLimit() {
        guard !selection.applicationTokens.isEmpty || !selection.categoryTokens.isEmpty || !selection.webDomainTokens.isEmpty else {
            statusMessage = "Avval cheklanadigan ilovalarni tanlang!"
            return
        }

        do {
            try Monitoring.start(minutes: minutes)
            isMonitoringActive = true
            statusMessage = "Monitoring boshlandi (\(minutes) daqiqa). Endi tanlangan ilovaga kirib foydalaning."
        } catch {
            statusMessage = "Monitoringni boshlashda xatolik: \(error.localizedDescription)"
        }
    }

    private func stopLimit() {
        Monitoring.stop()
        isMonitoringActive = false
        statusMessage = "Monitoring to'xtatildi. Barcha blokirovkalar olib tashlandi."
    }

    private func quickBlockTest() {
        guard !selection.applicationTokens.isEmpty || !selection.categoryTokens.isEmpty || !selection.webDomainTokens.isEmpty else {
            statusMessage = "Iltimos, avval ilovalarni tanlang!"
            return
        }
        Monitoring.applyShield()
        statusMessage = "Ilovalar darhol bloklandi. Tanlangan ilovani oching va 'Listen' tugmasini tekshiring."
    }

    private func resetAll() {
        Monitoring.resetAllRestrictions()
        denyDeletion = false
        lockDateTime = false
        isMonitoringActive = false
        statusMessage = "Barcha cheklovlar va blokirovkalar to'liq olib tashlandi."
    }
}
