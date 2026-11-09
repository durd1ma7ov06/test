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

/// Tells the UI to open the Listen screen when the notification is tapped.
@MainActor
final class Router: ObservableObject {
    static let shared = Router()
    @Published var showListen = false
}

final class AppDelegate: NSObject, UIApplicationDelegate, UNUserNotificationCenterDelegate {

    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil) -> Bool {
        // Must be set before launch finishes, or taps that cold-start the app are missed.
        UNUserNotificationCenter.current().delegate = self
        return true
    }

    // Called when the user taps our notification (cold-start or background)
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                didReceive response: UNNotificationResponse,
                                withCompletionHandler completionHandler: @escaping () -> Void) {
        let route = response.notification.request.content.userInfo["route"] as? String
        if route == "listen" { // must match StillsShieldAction
            DispatchQueue.main.async {
                Router.shared.showListen = true
            }
        }
        completionHandler()
    }

    // Show banner even when the app is already in the foreground
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                willPresent notification: UNNotification,
                                withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        completionHandler([.banner, .sound])
    }
}
