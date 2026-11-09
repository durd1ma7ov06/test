# iOS test build: Screen Time limit → shield → "Listen" → notification → app

> **Status:** test prototype only, not the real app. The goal is to prove the blocking mechanism works on a real iPhone.
> **Researched:** November 2026 (Xcode 27, iOS 27).

## 0. For AI coding agents: read this first

You are helping our CTO. He's an experienced programmer but has **never built anything for Apple**. When he asks what to build:

1. First explain the goal (section 1) and how it works (section 3) in plain words.
2. Walk him through **phases 1 to 5 in order, one phase at a time**. Wait for him to confirm a phase works before moving on.
3. Xcode setup (new project, targets, capabilities, signing) must be done **by him in the Xcode UI**. Give exact clicks. Never hand-edit `project.pbxproj`.
4. You may write and edit the Swift files in this repo (section 6). Keep the class names Xcode generates for the extensions.
5. No third-party SDKs, backend, analytics or private APIs. Don't build the real Stills feed. Stay in scope.
6. If something fails, check section 9 (troubleshooting) and section 10 (known iOS limitations) before changing code.
7. Only use the APIs named here. If you're not sure an API exists, say so instead of guessing.

## 1. What we're testing

1. He opens our test app.
2. He picks apps to limit (for example Instagram).
3. He sets a limit: 1–60 minutes. Use 2 for quick tests and 5–10 for real ones.
4. He leaves our app and uses Instagram.
5. When the limit is reached, iOS covers Instagram with our block screen (a **shield**) that has a **Listen** button.
6. He taps **Listen**, gets a notification from our app, taps it, and our app opens on a "Listen" screen. In the real app, this screen will be the **Stills** section.

Plus hardening tests (section 8): blocking app deletion, locking the clock, and what happens if he revokes access, deletes the app or restarts the phone.

**Done** means every item in the section 8 checklist has been tried on his iPhone and the results are written down.

## 2. What you need

| Need | Details |
|---|---|
| Mac | Apple silicon (M1 or newer) running macOS Tahoe 26.6 or later, which Xcode 27 requires. You can't build iPhone apps on Windows or Linux. |
| Xcode 27 | Free from the Mac App Store. Open it once and let it install any extra components it asks for. |
| iPhone | iOS 17.4 or newer (latest iOS 27 recommended) and a USB cable. Screen Time APIs **do not work in the Simulator**. |
| Paid Apple Developer Program | $99/year at developer.apple.com/programs/enroll. **Free accounts can't use Family Controls.** Xcode shows: "Personal development teams do not support the Family Controls (Development) capability." Enrolling from Uzbekistan can take days or weeks (ID and address checks, card payment problems have been reported), so start now. |
| Time | About 2–3 hours for a first-timer once the account is active. |

## 3. How it works (Apple concepts in plain words)

**The Screen Time API is 3 Apple frameworks:**
- **FamilyControls** asks the user for permission and shows Apple's app picker (`FamilyActivityPicker`).
- **DeviceActivity** tells iOS "watch these apps and call me when they've been used N minutes" (`DeviceActivityCenter`, `DeviceActivitySchedule`, `DeviceActivityEvent`).
- **ManagedSettings** applies the block. The block screen is called a **shield** (`ManagedSettingsStore().shield`).

**Why we need extensions.** When the limit hits, our app usually isn't running. So iOS runs small separate programs that ship inside our app, called app extensions:

| Target | Xcode template | Job |
|---|---|---|
| `StillsTest` (main app) | iOS App | Permission, app picker, limit, Listen screen |
| `StillsMonitor` | Device Activity Monitor Extension | Wakes up when the limit is reached and applies the shield |
| `StillsShieldConfig` | Shield Configuration Extension | Draws the shield: title, text and the **Listen** button |
| `StillsShieldAction` | Shield Action Extension | Runs when **Listen** or **Close** is tapped and posts the notification |

**App Group:** a shared storage area that the app and its extensions can all read. They are separate processes, so this is how they share data. We store the selected apps and the limit there.

**Capabilities (entitlements):** permissions built into the signed app. Every target needs **Family Controls**. The app and the monitor need the **App Group**. The development version of Family Controls works right away on your own phone. For TestFlight or the App Store, Apple must approve the distribution version later (section 12).

**Privacy:** Apple never tells us which apps the user picked. We get opaque **tokens**. We can block with them and display them with `Label(token)`, but we can't read app names as text.

**Why "Listen" goes through a notification:** Apple has no API that opens our app from the shield. The supported workaround is for the Shield Action extension to post a local notification. Tapping it opens our app. It costs one extra tap.

```
StillsTest app --saves selection + limit--> App Group storage <--reads-- StillsMonitor
      |                                                                     ^
      +-- startMonitoring("daily", event: N minutes) --> iOS --N min used---+
                                                                            |
StillsMonitor --applies shield--> ManagedSettings --> user opens Instagram
                                                  --> shield drawn by StillsShieldConfig ("Listen")
user taps Listen --> StillsShieldAction posts a notification and closes Instagram
user taps the notification --> StillsTest opens the Listen screen (later: Stills)
```

## 4. Phase 1: one-time setup

1. Enroll in the Apple Developer Program (paid) and wait until it's active.
2. Install Xcode 27 and open it. Go to Xcode → Settings → Accounts → **+** and sign in with the paid Apple Account.
3. On the iPhone, update iOS. Connect it with the cable, unlock it and tap **Trust This Computer**.
4. In Xcode, open Window → Devices and Simulators and wait until the iPhone shows as ready.
5. On the iPhone, go to Settings → Privacy & Security → **Developer Mode**, turn it on, restart, and confirm **Turn On**. This option only appears after the phone has been connected to Xcode.
6. Make sure the iPhone is signed in to an Apple Account (Settings → your name) and isn't a child account in Family Sharing.

## 5. Phase 2: create the project and targets (in Xcode)

Replace `YOURNAME` everywhere with something unique, for example `stillsapp`.

**5.1 The app**
1. File → New → Project → iOS → **App** → Next.
2. Product Name `StillsTest`, Team: your paid team, Organization Identifier `com.YOURNAME`, Interface **SwiftUI**, Language **Swift**, Testing System **None**, Storage **None**.
3. Save it inside this repo in a folder named `ios-test/`.
4. Click the blue project icon → target **StillsTest** → **General** → Minimum Deployments: **iOS 17.4**.
5. **Signing & Capabilities** → tick "Automatically manage signing" and pick your Team.
6. **+ Capability** → **Family Controls**.
7. **+ Capability** → **App Groups** → **+** → `group.com.YOURNAME.stillstest`.

**5.2 The three extensions.** For each row: File → New → Target → iOS → search for the template → Next → enter the Product Name → make sure **Embed in Application** is set to `StillsTest` → Finish. If Xcode asks "Activate scheme?", click **Activate**.

| Template | Product Name |
|---|---|
| Device Activity Monitor Extension | `StillsMonitor` |
| Shield Configuration Extension | `StillsShieldConfig` |
| Shield Action Extension | `StillsShieldAction` |

Then, for **each** of the 3 extension targets:
1. Signing & Capabilities → same Team → **+ Family Controls** → **+ App Groups** → tick `group.com.YOURNAME.stillstest`.
2. General → Minimum Deployments **iOS 17.4**. All 4 targets must match. A mismatch can stop the custom shield from showing.

Afterwards, switch the scheme in the top bar back to **StillsTest**.

You do **not** need the Push Notifications capability. These are local notifications.

**5.3 Build settings (recommended for this throwaway test).** For all 4 targets, open Build Settings and search for:
- `Swift Language Version` → **Swift 5**
- `Default Actor Isolation` → **nonisolated** (if the setting exists)

This avoids Swift 6 strict-concurrency errors that have nothing to do with what we're testing.

**5.4 Git.** Add `ios-test/.gitignore`:

```
xcuserdata/
DerivedData/
build/
*.xcuserstate
```

## 6. Phase 3: the code

In each extension, keep the class name Xcode generated, because the extension's Info.plist refers to it. Only replace the code inside. Replace `YOURNAME` in `Shared.swift` and in the loggers.

### 6.1 `Shared.swift` (targets: StillsTest + StillsMonitor)

Create it with File → New → File → Swift File. In the save dialog, tick **both** targets. To check later: select the file → right panel → File Inspector → Target Membership.

```swift
import Foundation
import FamilyControls
import ManagedSettings
import DeviceActivity

/// Shared between the app and the monitor extension (they are separate processes).
enum Shared {
    /// Must match the App Group in Signing & Capabilities on every target.
    static let appGroup = "group.com.YOURNAME.stillstest"
    static var defaults: UserDefaults { UserDefaults(suiteName: appGroup)! }

    static let selectionKey = "selection"
    static let limitMinutesKey = "limitMinutes"
    static let armedAtKey = "armedAt"
    static let rearmCountKey = "rearmCount"

    static func saveSelection(_ selection: FamilyActivitySelection) {
        if let data = try? JSONEncoder().encode(selection) {
            defaults.set(data, forKey: selectionKey)
        }
    }

    static func loadSelection() -> FamilyActivitySelection {
        guard let data = defaults.data(forKey: selectionKey),
              let selection = try? JSONDecoder().decode(FamilyActivitySelection.self, from: data)
        else { return FamilyActivitySelection() }
        return selection
    }
}

extension DeviceActivityName {
    static let daily = Self("daily")
}

extension DeviceActivityEvent.Name {
    static let limit = Self("limit")
}

extension ManagedSettingsStore.Name {
    static let limit = Self("limit")    // the block (shield)
    static let strict = Self("strict")  // hardening tests: deny app deletion, lock date & time
}

enum Monitoring {
    /// Starts (or restarts) an all-day schedule with one event:
    /// "the selected apps were used for `minutes` minutes".
    static func start(minutes: Int, isRearm: Bool = false) throws {
        let selection = Shared.loadSelection()

        // Only hour/minute here. Adding a day/date component can make events fire instantly.
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
            includesPastActivity: false   // count only usage from now on (iOS 17.4+)
        )

        let defaults = Shared.defaults
        defaults.set(minutes, forKey: Shared.limitMinutesKey)
        defaults.set(Date().timeIntervalSince1970, forKey: Shared.armedAtKey)
        if !isRearm { defaults.set(0, forKey: Shared.rearmCountKey) }

        let center = DeviceActivityCenter()
        center.stopMonitoring([.daily])
        try center.startMonitoring(.daily, during: schedule, events: [.limit: event])
    }

    /// Stops watching and removes the block.
    static func stop() {
        DeviceActivityCenter().stopMonitoring([.daily])
        removeShield()
    }

    static func applyShield() {
        let selection = Shared.loadSelection()
        let store = ManagedSettingsStore(named: .limit)
        // Empty sets are fine: they simply block nothing.
        store.shield.applications = selection.applicationTokens
        store.shield.applicationCategories = .specific(selection.categoryTokens)
        store.shield.webDomains = selection.webDomainTokens
    }

    static func removeShield() {
        ManagedSettingsStore(named: .limit).clearAllSettings()
    }
}
```

### 6.2 `StillsTestApp.swift` (target: StillsTest; replace the generated contents)

```swift
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

    // The user tapped our notification (works whether the app was in the background or closed).
    nonisolated func userNotificationCenter(_ center: UNUserNotificationCenter,
                                            didReceive response: UNNotificationResponse) async {
        let route = response.notification.request.content.userInfo["route"] as? String
        if route == "listen" {   // must match StillsShieldAction
            await MainActor.run { Router.shared.showListen = true }
        }
    }

    // Show the banner even when our app is already open.
    nonisolated func userNotificationCenter(_ center: UNUserNotificationCenter,
                                            willPresent notification: UNNotification) async -> UNNotificationPresentationOptions {
        [.banner, .sound]
    }
}
```

### 6.3 `ContentView.swift` (target: StillsTest; replace the generated contents)

```swift
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
            _ = try await UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound])
            status = "Permissions granted."
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
```

### 6.4 `ListenView.swift` (target: StillsTest; new file)

```swift
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
```

### 6.5 Monitor extension (target: StillsMonitor; replace the template code)

```swift
import DeviceActivity
import ManagedSettings
import Foundation
import os

private let log = Logger(subsystem: "com.YOURNAME.stillstest", category: "monitor")

// Keep the class name Xcode generated.
class DeviceActivityMonitorExtension: DeviceActivityMonitor {

    override func intervalDidStart(for activity: DeviceActivityName) {
        super.intervalDidStart(for: activity)
        log.info("intervalDidStart")
    }

    override func intervalDidEnd(for activity: DeviceActivityName) {
        super.intervalDidEnd(for: activity)
        log.info("intervalDidEnd: the day is over, removing the block")
        Monitoring.removeShield()
    }

    override func eventDidReachThreshold(_ event: DeviceActivityEvent.Name, activity: DeviceActivityName) {
        super.eventDidReachThreshold(event, activity: activity)

        // Known iOS bug (reported on iOS 26.x): this can fire seconds after monitoring starts.
        // Real usage can't reach N minutes in less than N minutes of clock time,
        // so an early call is fake. Ignore it and re-arm (at most 3 times).
        let defaults = Shared.defaults
        let armedAt = defaults.double(forKey: Shared.armedAtKey)
        let limit = defaults.integer(forKey: Shared.limitMinutesKey)
        let elapsed = Date().timeIntervalSince1970 - armedAt

        if armedAt > 0, limit > 0, elapsed < Double(limit * 60) - 10 {
            let rearms = defaults.integer(forKey: Shared.rearmCountKey)
            log.error("Threshold fired too early (\(Int(elapsed), privacy: .public)s). Re-arm #\(rearms + 1, privacy: .public)")
            guard rearms < 3 else {
                log.error("Gave up re-arming.")
                return
            }
            defaults.set(rearms + 1, forKey: Shared.rearmCountKey)
            try? Monitoring.start(minutes: limit, isRearm: true)
            return
        }

        log.info("Limit reached: applying the shield")
        Monitoring.applyShield()
    }
}
```

### 6.6 Shield configuration extension (target: StillsShieldConfig; replace the template code)

```swift
import ManagedSettings
import ManagedSettingsUI
import UIKit

// Keep the class name Xcode generated.
class ShieldConfigurationExtension: ShieldConfigurationDataSource {

    private func listenShield() -> ShieldConfiguration {
        ShieldConfiguration(
            backgroundBlurStyle: .systemUltraThinMaterialDark,
            backgroundColor: UIColor.black.withAlphaComponent(0.85),
            icon: UIImage(systemName: "headphones")?.withTintColor(.white, renderingMode: .alwaysOriginal),
            title: ShieldConfiguration.Label(text: "Time's up", color: .white),
            subtitle: ShieldConfiguration.Label(text: "Listen to something calm to earn minutes back.", color: .lightGray),
            primaryButtonLabel: ShieldConfiguration.Label(text: "Listen", color: .black),
            primaryButtonBackgroundColor: .white,
            secondaryButtonLabel: ShieldConfiguration.Label(text: "Close", color: .white)
        )
    }

    override func configuration(shielding application: Application) -> ShieldConfiguration {
        listenShield()
    }

    override func configuration(shielding application: Application, in category: ActivityCategory) -> ShieldConfiguration {
        listenShield()
    }

    override func configuration(shielding webDomain: WebDomain) -> ShieldConfiguration {
        listenShield()
    }

    override func configuration(shielding webDomain: WebDomain, in category: ActivityCategory) -> ShieldConfiguration {
        listenShield()
    }
}
```

### 6.7 Shield action extension (target: StillsShieldAction; replace the template code)

```swift
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
            // Apple has no API to open our app from a shield.
            // Supported workaround: post a local notification. Tapping it opens the app.
            let content = UNMutableNotificationContent()
            content.title = "Tap to listen 🎧"
            content.body = "Open the app to earn minutes back."
            content.sound = .default
            content.userInfo = ["route": "listen"]   // must match AppDelegate

            let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: nil)
            UNUserNotificationCenter.current().add(request) { error in
                if let error {
                    log.error("Notification failed: \(error.localizedDescription, privacy: .public)")
                }
                completionHandler(.close)   // closes the blocked app so the banner is easy to see
            }

        default:
            // "Close" (secondary button) and any newer actions
            completionHandler(.close)
        }
    }
}
```

## 7. Phase 4: run it on the iPhone

1. Plug in the iPhone. In the top bar, pick scheme **StillsTest** and destination **your iPhone**.
2. Press ▶ (Cmd+R). The first build takes a few minutes.
3. If the iPhone says "Untrusted Developer": Settings → General → VPN & Device Management → your developer profile → Trust.
4. In the app, tap **Allow Screen Time + notifications** → continue → Face ID → allow notifications.
5. Optional: after the first run over the cable, Window → Devices and Simulators → tick **Connect via network** to install over Wi-Fi.

## 8. Phase 5: test checklist

**Core flow**
- [ ] Tap **Choose apps to limit**, pick one app you use (for example Instagram), tap Done. Its icon and name appear in the list.
- [ ] Set the limit to 2 min and tap **Start limit**. The status says "Limit started".
- [ ] Open that app and really use it (screen on, scrolling) for 2+ minutes. The shield appears with **Listen**. It can lag by up to a minute.
- [ ] Tap **Listen**. The app closes and a StillsTest banner appears within 1–2 seconds.
- [ ] Tap the banner. StillsTest opens on the **Listen** screen.
- [ ] Repeat, but first fully close StillsTest (swipe it away in the app switcher) before tapping Listen. Tapping the banner should still open the Listen screen.
- [ ] On the Listen screen, tap **I listened → give me 5 minutes**. The app works again, and after 5 more minutes of use it's blocked again.
- [ ] Repeat the whole flow with 5 and 10 minutes.
- [ ] Tap **Close** on the shield. The blocked app closes and no notification appears.
- [ ] Tap **Block now**, then open the chosen app. The shield appears instantly (a fast way to retest Listen).
- [ ] Tap **Stop + unblock**. Everything opens normally.

**Hardening** (write down what happens each time)
- [ ] Turn **Prevent deleting apps** ON, then long-press any app → Remove App. Expected: deleting is blocked for every app, not just ours. Turn it OFF and deleting works again.
  - ⚠️ Developers have reported this setting staying stuck on even after it was turned off and the app was deleted, and the only fix was resetting the phone. Always tap **Reset everything** before deleting StillsTest. If you have a spare iPhone, use it for this test.
- [ ] With **Lock date & time** OFF: hit a limit, then change the clock (Settings → General → Date & Time). Does the block disappear? That's a known bypass. Then turn the toggle ON: "Set Automatically" should now be locked.
- [ ] Revoke access: Settings → Screen Time → Apps With Screen Time Access (or Settings → Apps → StillsTest) → turn it off. Expected: all blocks lift immediately and our app isn't told. Note whether it asks for Face ID or the passcode.
- [ ] With **Prevent deleting apps** OFF, delete StillsTest while something is blocked. Expected: iOS removes its blocks. Reinstall from Xcode afterwards.
- [ ] Restart the iPhone while a limit is running. Does the limit still trigger after the restart?
- [ ] Leave a limit on overnight. After midnight the block should be gone (new day).

## 9. Debugging and troubleshooting

**See logs:** on the Mac, open the **Console** app → select the iPhone in the sidebar → Start → search `com.YOURNAME.stillstest`. The extensions log there.

**Breakpoints in an extension:** run StillsTest from Xcode first. Then Debug → Attach to Process by PID or Name… → type the extension's name (for example `StillsMonitor`) → Attach. Xcode waits until iOS launches it.

| Problem | Fix |
|---|---|
| "Personal development teams do not support the Family Controls…" | Select the paid Apple Developer Program team in Signing on every target. |
| The app picker is empty or shows no apps | You're in the Simulator (use a real iPhone), or permission wasn't granted yet. |
| Install fails because a newer iOS is needed | Set Minimum Deployments to 17.4 on all 4 targets. |
| "Embedded binary's bundle identifier is not prefixed with the parent app's" | Extension bundle IDs must start with the app's bundle ID, e.g. `com.YOURNAME.StillsTest.StillsMonitor`. |
| The shield never appears | Check: the monitor target has Family Controls and the App Group; the App Group string matches `Shared.appGroup`; you tapped Start limit again after changing apps; you really used the app long enough; the extension didn't crash (look in Console for memory or "jetsam" messages). |
| The monitor sees no selected apps | The App Group isn't identical on both targets. iOS then quietly gives each process its own storage. |
| The shield appears right after starting | Known iOS bug (section 10). The logs should say "fired too early" and re-arm. |
| The default iOS shield appears instead of ours | The Shield Configuration extension is missing Family Controls, isn't embedded, or its Minimum Deployments differs from the app's. |
| Tapping Listen shows no banner | Notifications not allowed (Settings → Notifications → StillsTest), Focus or Do Not Disturb is on, or Notification Summary / Apple Intelligence prioritization is delaying it. Optional: add the **Time Sensitive Notifications** capability and set `content.interruptionLevel = .timeSensitive`. |
| The banner opens the app but not the Listen screen | `UNUserNotificationCenter.current().delegate = self` must run in `didFinishLaunchingWithOptions`, and `"route": "listen"` must match in both files. |
| Swift concurrency errors | Use the section 5.3 settings (Swift 5 + nonisolated). |
| "Untrusted Developer" | Settings → General → VPN & Device Management → Trust. |

## 10. Known iOS limitations (don't fight these)

- **No "open my app" from the shield.** Developers, including the maker of one sec, have kept asking Apple for this through 2025–2026 with no answer. A local notification plus a tap is the supported way. Don't use private-API tricks or SDKs that claim to skip it: developers report App Review rejections.
- **The limit can fire early.** Reported on iOS 26.0 through 26.5.2: `eventDidReachThreshold` firing seconds after `startMonitoring`, even with `includesPastActivity: false`. Our clock-time guard handles this. Check whether it still happens on iOS 27 and note it.
- **Long timers are less reliable.** Some developers report callbacks becoming unreliable beyond about 45 minutes. Test short limits first.
- **6 MB memory limit** in the monitor extension. Keep it tiny: no big libraries, no Firebase, no images.
- **Schedules must be at least 15 minutes long (and at most a week)**, otherwise you get `intervalTooShort`. The usage threshold itself can be shorter (1 minute is fine). For short "breaks", developers use `warningTime`.
- **Users can always revoke access** (individual authorization) in Settings. That lifts every block instantly and our app isn't told. So for adults, "can't delete" is friction, not a lock. Real delete protection only exists for child accounts in Family Sharing, where a parent must approve.
- **iOS 27** redesigned Screen Time for parents but didn't fix these developer-side gaps.

## 11. Product ideas to test (from research)

1. **Give a real "not now".** In a peer-reviewed study of the app one sec (PNAS 2023, 280 users over 6 weeks), the option to dismiss had the strongest effect, a short wait also helped, and a message on its own didn't. App openings fell 57%. So keep **Close** visible next to **Listen**, and try a calm 5–10 second pause before content starts.
2. **Make "no delete" an opt-in strict mode, not the default.** It blocks deleting *every* app, can be revoked in Settings, and has been reported to get stuck. Always clear it when strict mode ends.
3. **Lock date & time** in strict mode so changing the clock can't skip limits.
4. **Let users pick how long to listen, right on the shield.** iOS 26.4+ supports up to 3 submenu items on the secondary button (`secondaryButtonSubmenuItems`, handled as `.firstSecondarySubmenuItemPressed` and so on). For example "1-min idea", "5 min" and "20-min episode". Each can post the same notification with a different route.
5. **Block categories and websites too** (for example the whole Social category plus instagram.com in Safari) so the browser isn't an escape route.
6. Show what's blocked with `Label(token)`. Never try to read app names.

## 12. After this test (toward the real app)

- Change the `"listen"` route so it opens the Stills section (the short ideas).
- Before TestFlight or the App Store, request **Family Controls (Distribution)** from Apple for the app and every extension. Developers report that the old per-app form has been replaced by a single account-level request form. Approval takes time, so request it early.
- Keep the logic in the main app and keep the extensions minimal.

## 13. References

- Family Controls: https://developer.apple.com/documentation/familycontrols
- Device Activity: https://developer.apple.com/documentation/deviceactivity
- Managed Settings: https://developer.apple.com/documentation/managedsettings
- Shield appearance: https://developer.apple.com/documentation/managedsettingsui/shieldconfiguration
- WWDC21 "Meet the Screen Time API": https://developer.apple.com/videos/play/wwdc2021/10123/
- Family Controls needs a paid team: https://developer.apple.com/forums/thread/764682
- Opening the app from the shield isn't supported: https://developer.apple.com/forums/thread/793060
- iOS 26 early-threshold bug: https://developer.apple.com/forums/thread/808470
- 15-minute minimum schedule: https://developer.apple.com/forums/thread/747557
- 6 MB monitor memory limit: https://developer.apple.com/forums/thread/827783
- denyAppRemoval with individual authorization: https://developer.apple.com/forums/thread/729717
- denyAppRemoval stuck reports: https://developer.apple.com/forums/thread/818905
- Revoking individual authorization: https://developer.apple.com/forums/thread/820796
- one sec study (PNAS 2023): https://www.pnas.org/doi/10.1073/pnas.2213114120
