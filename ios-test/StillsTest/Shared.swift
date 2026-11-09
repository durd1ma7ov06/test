import Foundation
import FamilyControls
import ManagedSettings
import DeviceActivity
import os

private let logger = Logger(subsystem: "com.stills.app", category: "shared")

/// Asosiy ilova va uning extension'lari (Monitor, Shield) o'rtasida umumiy xotira va konfiguratsiya
public enum Shared {
    /// Diqqat: Bu ID Xcode'dagi App Group bilan aynan bir xil bo'lishi shart!
    /// Agar o'zgartirmoqchi bo'lsangiz, faqat shu yerni o'zgartirish kifoya.
    public static var appGroup = "group.com.stills.app"

    public static var defaults: UserDefaults {
        if let sharedDefaults = UserDefaults(suiteName: appGroup) {
            return sharedDefaults
        }
        logger.error("App Group UserDefaults '\(appGroup, privacy: .public)' mavjud emas. Standart xotiraga o'tilmoqda.")
        return .standard
    }

    public static let selectionKey = "selection"
    public static let limitMinutesKey = "limitMinutes"
    public static let armedAtKey = "armedAt"
    public static let rearmCountKey = "rearmCount"

    public static func saveSelection(_ selection: FamilyActivitySelection) {
        do {
            let data = try JSONEncoder().encode(selection)
            defaults.set(data, forKey: selectionKey)
            logger.info("Ilovalar tanlovi saqlandi (Apps: \(selection.applicationTokens.count), Categories: \(selection.categoryTokens.count))")
        } catch {
            logger.error("Ilovalar tanlovini saqlashda xatolik: \(error.localizedDescription, privacy: .public)")
        }
    }

    public static func loadSelection() -> FamilyActivitySelection {
        guard let data = defaults.data(forKey: selectionKey),
              let selection = try? JSONDecoder().decode(FamilyActivitySelection.self, from: data)
        else {
            return FamilyActivitySelection()
        }
        return selection
    }
}

public extension DeviceActivityName {
    static let daily = Self("daily")
}

public extension DeviceActivityEvent.Name {
    static let limit = Self("limit")
}

public extension ManagedSettingsStore.Name {
    static let limit = Self("limit")    // Bloklash ekrani (Shield)
    static let strict = Self("strict")  // Xavfsizlik cheklovlari (o'chirishni bloklash, soatni qulflash)
}

public enum Monitoring {
    /// Monitoring va limitni ishga tushirish (yoki qayta ishga tushirish)
    public static func start(minutes: Int, isRearm: Bool = false) throws {
        let selection = Shared.loadSelection()

        guard !selection.applicationTokens.isEmpty || !selection.categoryTokens.isEmpty || !selection.webDomainTokens.isEmpty else {
            logger.warning("Monitoring boshlanmadi: birorta ham ilova yoki toifa tanlanmagan.")
            return
        }

        // Apple talabi: Schedule kamida 15 daqiqa bo'lishi kerak.
        // Butun kunlik jadval: 00:00 dan 23:59 gacha.
        let schedule = DeviceActivitySchedule(
            intervalStart: DateComponents(hour: 0, minute: 0),
            intervalEnd: DateComponents(hour: 23, minute: 59),
            repeats: true
        )

        let event = DeviceActivityEvent(
            applications: selection.applicationTokens,
            categories: selection.categoryTokens,
            webDomains: selection.webDomainTokens,
            threshold: DateComponents(minute: minutes),
            includesPastActivity: false // Faqat hozirdan boshlab hisoblaydi
        )

        let defaults = Shared.defaults
        defaults.set(minutes, forKey: Shared.limitMinutesKey)

        // MUHIM TUZATMA: Agar re-arm (erta chalg'ishdan qayta boshlash) bo'lsa,
        // dastlabki boshlangan vaqtni o'chirib yubormaslik kerak!
        if !isRearm {
            defaults.set(Date().timeIntervalSince1970, forKey: Shared.armedAtKey)
            defaults.set(0, forKey: Shared.rearmCountKey)
        }

        let center = DeviceActivityCenter()
        center.stopMonitoring([.daily])
        try center.startMonitoring(.daily, during: schedule, events: [.limit: event])
        logger.info("Monitoring faollashtirildi: \(minutes) daqiqa (isRearm: \(isRearm))")
    }

    /// Monitoringni to'xtatish va blokni olib tashlash
    public static func stop() {
        DeviceActivityCenter().stopMonitoring([.daily])
        removeShield()
        logger.info("Monitoring to'xtatildi va blok olib tashlandi.")
    }

    /// Bloklash ekranini (Shield) darhol faollashtirish
    public static func applyShield() {
        let selection = Shared.loadSelection()
        let store = ManagedSettingsStore(named: .limit)

        store.shield.applications = selection.applicationTokens.isEmpty ? nil : selection.applicationTokens
        store.shield.applicationCategories = selection.categoryTokens.isEmpty ? nil : .specific(selection.categoryTokens)
        store.shield.webDomains = selection.webDomainTokens.isEmpty ? nil : selection.webDomainTokens
        logger.info("Bloklash ekrani (Shield) o'rnatildi.")
    }

    /// Bloklash ekranini olib tashlash
    public static func removeShield() {
        ManagedSettingsStore(named: .limit).clearAllSettings()
        logger.info("Bloklash ekrani olib tashlandi.")
    }

    /// Barcha cheklovlarni (jumladan xavfsizlik cheklovlarini) to'liq xavfsiz tozalash
    public static func resetAllRestrictions() {
        stop()
        let strictStore = ManagedSettingsStore(named: .strict)
        // iOS xatoligini oldini olish uchun avval false qilib, keyin tozalanadi:
        strictStore.application.denyAppRemoval = false
        strictStore.dateAndTime.requireAutomaticDateAndTime = false
        strictStore.clearAllSettings()
        logger.info("Barcha cheklovlar to'liq tozalandi.")
    }
}
