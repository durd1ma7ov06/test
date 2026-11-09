import Foundation
import FamilyControls
import ManagedSettings
import DeviceActivity
import os

private let logger = Logger(subsystem: "com.YOURNAME.stillstest", category: "shared")

/// Shared between the app and the monitor extension (they are separate processes).
public enum Shared {
    /// Must match the App Group in Signing & Capabilities on every target.
    public static let appGroup = "group.com.YOURNAME.stillstest"

    public static var defaults: UserDefaults {
        if let sharedDefaults = UserDefaults(suiteName: appGroup) {
            return sharedDefaults
        }
        logger.error("App Group UserDefaults '\(appGroup, privacy: .public)' unavailable. Falling back to standard defaults.")
        return .standard
    }

    public static let selectionKey = "selection"
    public static let limitMinutesKey = "limitMinutes"
    public static let armedAtKey = "armedAt"
    public static let rearmCountKey = "rearmCount"

    public static func saveSelection(_ selection: FamilyActivitySelection) {
        if let data = try? JSONEncoder().encode(selection) {
            defaults.set(data, forKey: selectionKey)
        }
    }

    public static func loadSelection() -> FamilyActivitySelection {
        guard let data = defaults.data(forKey: selectionKey),
              let selection = try? JSONDecoder().decode(FamilyActivitySelection.self, from: data)
        else { return FamilyActivitySelection() }
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
    static let limit = Self("limit")    // the block (shield)
    static let strict = Self("strict")  // hardening tests: deny app deletion, lock date & time
}

public enum Monitoring {
    /// Starts (or restarts) an all-day schedule with one event:
    /// "the selected apps were used for `minutes` minutes".
    public static func start(minutes: Int, isRearm: Bool = false) throws {
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
    public static func stop() {
        DeviceActivityCenter().stopMonitoring([.daily])
        removeShield()
    }

    public static func applyShield() {
        let selection = Shared.loadSelection()
        let store = ManagedSettingsStore(named: .limit)
        // Cleanly assign or reset tokens
        store.shield.applications = selection.applicationTokens.isEmpty ? nil : selection.applicationTokens
        store.shield.applicationCategories = selection.categoryTokens.isEmpty ? nil : .specific(selection.categoryTokens)
        store.shield.webDomains = selection.webDomainTokens.isEmpty ? nil : selection.webDomainTokens
    }

    public static func removeShield() {
        ManagedSettingsStore(named: .limit).clearAllSettings()
    }
}
