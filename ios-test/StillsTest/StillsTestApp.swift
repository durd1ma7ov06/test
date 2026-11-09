import SwiftUI
import UserNotifications

@main
struct StillsTestApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}

/// Ilova navigatsiyasini boshqaruvchi markaziy router
@MainActor
final class Router: ObservableObject {
    static let shared = Router()
    @Published var showListen: Bool = false
}

/// Bildirishnomalarni boshqaruvchi delegat
final class AppDelegate: NSObject, UIApplicationDelegate, UNUserNotificationCenterDelegate {

    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil) -> Bool {
        // Ilova ishga tushishi bilan delegatni tayinlash shart (cold-start o'tkazib yuborilmasligi uchun)
        UNUserNotificationCenter.current().delegate = self
        return true
    }

    // Foydalanuvchi bildirishnomani bosganda (Ilova yopiq bo'lsa ham yoki orqa fonda bo'lsa ham)
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                didReceive response: UNNotificationResponse,
                                withCompletionHandler completionHandler: @escaping () -> Void) {
        let route = response.notification.request.content.userInfo["route"] as? String

        if route == "listen" {
            Task { @MainActor in
                Router.shared.showListen = true
            }
        }
        completionHandler()
    }

    // Ilova ochiq (foreground) turgan vaqtda bildirishnoma kelsa ham bannerni ko'rsatish
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                willPresent notification: UNNotification,
                                withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        if #available(iOS 14.0, *) {
            completionHandler([.banner, .sound, .badge])
        } else {
            completionHandler([.alert, .sound])
        }
    }
}
