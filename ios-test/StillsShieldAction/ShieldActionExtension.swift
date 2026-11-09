import Foundation
import ManagedSettings
import UserNotifications
import os

private let log = Logger(subsystem: "com.YOURNAME.stillstest", category: "shield-action")

// Keep the class name Xcode generated.
class ShieldActionExtension: ShieldActionDelegate {

    override func handle(action: ShieldAction, for application: ApplicationToken,
                         completionHandler: @escaping (ShieldActionResponse) -> Void) {
        handleTap(action, completionHandler: completionHandler)
    }

    override func handle(action: ShieldAction, for webDomain: WebDomainToken,
                         completionHandler: @escaping (ShieldActionResponse) -> Void) {
        handleTap(action, completionHandler: completionHandler)
    }

    override func handle(action: ShieldAction, for category: ActivityCategoryToken,
                         completionHandler: @escaping (ShieldActionResponse) -> Void) {
        handleTap(action, completionHandler: completionHandler)
    }

    private func handleTap(_ action: ShieldAction,
                           completionHandler: @escaping (ShieldActionResponse) -> Void) {
        switch action {
        case .primaryButtonPressed:
            // Apple has no API to open our app directly from a shield.
            // Supported workaround: post an immediate local notification. Tapping it opens the app.
            let content = UNMutableNotificationContent()
            content.title = "Tap to listen 🎧"
            content.body = "Open the app to earn minutes back."
            content.sound = .default
            content.userInfo = ["route": "listen"] // must match AppDelegate
            if #available(iOS 15.0, *) {
                content.interruptionLevel = .timeSensitive
            }

            let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: nil)
            UNUserNotificationCenter.current().add(request) { error in
                if let error {
                    log.error("Notification failed: \(error.localizedDescription, privacy: .public)")
                }
                completionHandler(.close) // closes the blocked app so the banner is immediately visible
            }

        default:
            // "Close" (secondary button) and any newer actions
            completionHandler(.close)
        }
    }
}
