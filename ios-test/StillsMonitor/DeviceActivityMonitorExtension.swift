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

        // Known iOS bug (reported on iOS 26.x / early releases): threshold can fire seconds after monitoring starts.
        // Real usage can't reach N minutes in less than N minutes of clock time.
        // If elapsed time is significantly less than threshold, ignore early false-positive and re-arm (max 3 attempts).
        let defaults = Shared.defaults
        let armedAt = defaults.double(forKey: Shared.armedAtKey)
        let limit = defaults.integer(forKey: Shared.limitMinutesKey)
        let now = Date().timeIntervalSince1970
        let elapsed = now - armedAt

        if armedAt > 0, limit > 0, elapsed >= 0, elapsed < Double(limit * 60) - 10 {
            let rearms = defaults.integer(forKey: Shared.rearmCountKey)
            log.error("Threshold fired too early (\(Int(elapsed), privacy: .public)s). Re-arm #\(rearms + 1, privacy: .public)")
            guard rearms < 3 else {
                log.error("Gave up re-arming after 3 attempts.")
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
