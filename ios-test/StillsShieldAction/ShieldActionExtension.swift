import Foundation
import ManagedSettings
import UserNotifications
import os

private let log = Logger(subsystem: "com.stills.app", category: "shield-action")

/// ShieldActionExtension
/// Bloklash ekranidagi tugmalar (Primary - "Listen", Secondary - "Close") bosilganda chaqiriladi.
class ShieldActionExtension: ShieldActionDelegate {

    override func handle(action: ShieldAction, for application: ApplicationToken,
                         completionHandler: @escaping (ShieldActionResponse) -> Void) {
        handleAction(action, completionHandler: completionHandler)
    }

    override func handle(action: ShieldAction, for webDomain: WebDomainToken,
                         completionHandler: @escaping (ShieldActionResponse) -> Void) {
        handleAction(action, completionHandler: completionHandler)
    }

    override func handle(action: ShieldAction, for category: ActivityCategoryToken,
                         completionHandler: @escaping (ShieldActionResponse) -> Void) {
        handleAction(action, completionHandler: completionHandler)
    }

    private func handleAction(_ action: ShieldAction,
                              completionHandler: @escaping (ShieldActionResponse) -> Void) {
        switch action {
        case .primaryButtonPressed:
            log.info("Primary button ('Listen') bosildi.")

            // Apple cheklovi: Shield ekrandan to'g'ridan-to'g'ri ilovaga o'tib bo'lmaydi.
            // Rasmiy tavsiya: Darhol mahalliy bildirishnoma (Local Notification) chiqariladi.
            let content = UNMutableNotificationContent()
            content.title = "Stills: Diqqatni jamlash 🎧"
            content.body = "Qayta daqiqalar olish uchun bosing va qisqa audioni tinglang."
            content.sound = .default
            content.userInfo = ["route": "listen"] // AppDelegate tomonidan ushlanadi

            if #available(iOS 15.0, *) {
                content.interruptionLevel = .timeSensitive
            }

            let request = UNNotificationRequest(
                identifier: UUID().uuidString,
                content: content,
                trigger: nil // Darhol chiqarish
            )

            UNUserNotificationCenter.current().add(request) { error in
                if let error = error {
                    log.error("Bildirishnoma yuborishda xatolik: \(error.localizedDescription, privacy: .public)")
                } else {
                    log.info("Bildirishnoma muvaffaqiyatli yuborildi.")
                }
                // Bloklangan ilovani yopish (shunda bildirishnoma banneri darhol ko'rinadi)
                completionHandler(.close)
            }

        default:
            log.info("Secondary button ('Close') yoki boshqa amal tanlandi.")
            completionHandler(.close)
        }
    }
}
