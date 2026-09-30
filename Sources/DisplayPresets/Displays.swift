import AppKit
import CoreGraphics

/// A currently connected, active display.
struct ConnectedDisplay {
    let id: CGDirectDisplayID
    /// Stable identifier that survives reconnects (unlike CGDirectDisplayID).
    let uuid: String
    let name: String
    let origin: CGPoint
    let isBuiltin: Bool
}

enum DisplayError: LocalizedError {
    case cg(String, CGError)
    case missingDisplays([String])

    var errorDescription: String? {
        switch self {
        case let .cg(step, err): return "\(step) failed (CGError \(err.rawValue))"
        case let .missingDisplays(names): return "Not connected: \(names.joined(separator: ", "))"
        }
    }
}

enum Displays {
    static func connected() -> [ConnectedDisplay] {
        var count: UInt32 = 0
        guard CGGetActiveDisplayList(0, nil, &count) == .success, count > 0 else { return [] }
        var ids = [CGDirectDisplayID](repeating: 0, count: Int(count))
        guard CGGetActiveDisplayList(count, &ids, &count) == .success else { return [] }

        return ids.prefix(Int(count)).compactMap { id in
            // In a mirror set only the primary display has a meaningful origin.
            if CGDisplayIsInMirrorSet(id) != 0, CGDisplayMirrorsDisplay(id) != kCGNullDirectDisplay {
                return nil
            }
            guard let uuid = uuidString(for: id) else { return nil }
            return ConnectedDisplay(
                id: id,
                uuid: uuid,
                name: localizedName(for: id),
                origin: CGDisplayBounds(id).origin,
                isBuiltin: CGDisplayIsBuiltin(id) != 0
            )
        }
    }

    static func uuidString(for id: CGDirectDisplayID) -> String? {
        guard let cfUUID = CGDisplayCreateUUIDFromDisplayID(id)?.takeRetainedValue() else { return nil }
        return CFUUIDCreateString(nil, cfUUID) as String
    }

    static func localizedName(for id: CGDirectDisplayID) -> String {
        let key = NSDeviceDescriptionKey("NSScreenNumber")
        let screen = NSScreen.screens.first { ($0.deviceDescription[key] as? NSNumber)?.uint32Value == id }
        if let name = screen?.localizedName { return name }
        return CGDisplayIsBuiltin(id) != 0 ? "Built-in Display" : "Display \(id)"
    }

    /// Moves displays to the origins stored in the preset. The display placed at (0,0) becomes main.
    static func apply(_ preset: Preset) throws {
        let byUUID = Dictionary(connected().map { ($0.uuid, $0) }, uniquingKeysWith: { a, _ in a })
        let missing = preset.displays.filter { byUUID[$0.uuid] == nil }.map(\.name)
        guard missing.isEmpty else { throw DisplayError.missingDisplays(missing) }

        var config: CGDisplayConfigRef?
        var err = CGBeginDisplayConfiguration(&config)
        guard err == .success, let config else { throw DisplayError.cg("Begin configuration", err) }

        for placement in preset.displays {
            guard let display = byUUID[placement.uuid] else { continue }
            err = CGConfigureDisplayOrigin(config, display.id, placement.x, placement.y)
            if err != .success {
                CGCancelDisplayConfiguration(config)
                throw DisplayError.cg("Set origin for \(placement.name)", err)
            }
        }

        err = CGCompleteDisplayConfiguration(config, .permanently)
        guard err == .success else { throw DisplayError.cg("Complete configuration", err) }
    }
}
