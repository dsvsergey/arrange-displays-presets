import Foundation
import IOKit.pwr_mgt

/// Prevents idle sleep (system and display) while enabled. The setting persists across launches.
/// Closing the lid without an external display still sleeps the Mac — that needs root (pmset).
final class KeepAwake {
    private static let defaultsKey = "keepAwake"
    private var assertionID: IOPMAssertionID = 0

    private(set) var isEnabled = false

    init() {
        if UserDefaults.standard.bool(forKey: Self.defaultsKey) {
            enable()
        }
    }

    func toggle() {
        isEnabled ? disable() : enable()
        UserDefaults.standard.set(isEnabled, forKey: Self.defaultsKey)
    }

    private func enable() {
        guard !isEnabled else { return }
        let result = IOPMAssertionCreateWithName(
            kIOPMAssertionTypePreventUserIdleDisplaySleep as CFString,
            IOPMAssertionLevel(kIOPMAssertionLevelOn),
            "Display Presets: Keep Awake" as CFString,
            &assertionID)
        isEnabled = result == kIOReturnSuccess
    }

    private func disable() {
        guard isEnabled else { return }
        IOPMAssertionRelease(assertionID)
        isEnabled = false
    }
}
