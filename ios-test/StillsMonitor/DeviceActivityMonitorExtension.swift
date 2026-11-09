import DeviceActivity
import ManagedSettings
import Foundation
import os

private let log = Logger(subsystem: "com.stills.app", category: "monitor")

/// DeviceActivityMonitorExtension
/// iOS tomonidan berilgan xotira chegarasi: MAKSIMAL 6 MB!
/// Og'ir kutubxonalar yoki katta hajmdagi ob'ektlar ishlatilmaydi.
class DeviceActivityMonitorExtension: DeviceActivityMonitor {

    override func intervalDidStart(for activity: DeviceActivityName) {
        super.intervalDidStart(for: activity)
        log.info("Kunlik interval boshlandi (intervalDidStart)")
    }

    override func intervalDidEnd(for activity: DeviceActivityName) {
        super.intervalDidEnd(for: activity)
        log.info("Kun tugadi (intervalDidEnd). Blokirovka bekor qilinmoqda...")
        Monitoring.removeShield()
    }

    override func eventDidReachThreshold(_ event: DeviceActivityEvent.Name, activity: DeviceActivityName) {
        super.eventDidReachThreshold(event, activity: activity)

        let defaults = Shared.defaults
        let armedAt = defaults.double(forKey: Shared.armedAtKey)
        let limitMinutes = defaults.integer(forKey: Shared.limitMinutesKey)
        let now = Date().timeIntervalSince1970
        let elapsedSeconds = now - armedAt

        let targetSeconds = Double(limitMinutes * 60)

        // iOS tizimlaridagi ma'lum xatolik:
        // Monitoring boshlangandan so'ng bir necha soniya ichida threshold asossiz ishlab ketishi mumkin.
        // Agar o'tgan vaqt belgilangan vaqtdan sezilarli darajada kam bo'lsa (10 soniya bufer bilan),
        // bu soxta signal hisoblanadi va qayta qurollantiriladi (maksimal 3 marta).
        if armedAt > 0 && limitMinutes > 0 && elapsedSeconds >= 0 && elapsedSeconds < (targetSeconds - 10) {
            let rearms = defaults.integer(forKey: Shared.rearmCountKey)
            log.warning("Threshold juda erta ishladi (O'tgan vaqt: \(Int(elapsedSeconds))s / Kerak: \(Int(targetSeconds))s). Qayta urinish #\(rearms + 1)")

            guard rearms < 3 else {
                log.error("3 marta qayta urinishdan so'ng to'xtatildi. Blok yoqilmoqda.")
                Monitoring.applyShield()
                return
            }

            defaults.set(rearms + 1, forKey: Shared.rearmCountKey)
            // Qolgan vaqtni hisobga olgan holda qayta boshlash
            let remainingMinutes = max(1, Int(ceil((targetSeconds - elapsedSeconds) / 60.0)))
            try? Monitoring.start(minutes: remainingMinutes, isRearm: true)
            return
        }

        log.info("Belgilangan limitga (\(limitMinutes) daqiqa) yetildi: Bloklash ekrani yoqilmoqda.")
        Monitoring.applyShield()
    }
}
