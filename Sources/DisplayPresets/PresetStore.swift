import Foundation

struct DisplayPlacement: Codable, Equatable {
    var uuid: String
    var name: String
    var x: Int32
    var y: Int32
}

struct Preset: Codable, Equatable {
    var name: String
    var displays: [DisplayPlacement]
    /// Apply automatically when exactly this set of displays gets connected.
    var autoApply: Bool?

    var displaySet: Set<String> { Set(displays.map(\.uuid)) }

    static func fromCurrent(named name: String) -> Preset {
        let placements = Displays.connected().map {
            DisplayPlacement(uuid: $0.uuid, name: $0.name, x: Int32($0.origin.x), y: Int32($0.origin.y))
        }
        return Preset(name: name, displays: placements)
    }

    /// All displays of the preset are currently connected.
    func isAvailable(in connected: [ConnectedDisplay]) -> Bool {
        let uuids = Set(connected.map(\.uuid))
        return displays.allSatisfy { uuids.contains($0.uuid) }
    }

    /// The current arrangement equals this preset.
    func isActive(in connected: [ConnectedDisplay]) -> Bool {
        guard connected.count == displays.count else { return false }
        let byUUID = Dictionary(connected.map { ($0.uuid, $0) }, uniquingKeysWith: { a, _ in a })
        return displays.allSatisfy { p in
            guard let d = byUUID[p.uuid] else { return false }
            return Int32(d.origin.x) == p.x && Int32(d.origin.y) == p.y
        }
    }
}

/// Presets persisted as JSON in ~/Library/Application Support/DisplayPresets/presets.json.
final class PresetStore {
    private(set) var presets: [Preset] = []
    let fileURL: URL

    init() {
        let base = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        fileURL = base.appendingPathComponent("DisplayPresets/presets.json")
        load()
    }

    func load() {
        guard let data = try? Data(contentsOf: fileURL),
              let decoded = try? JSONDecoder().decode([Preset].self, from: data) else { return }
        presets = decoded
    }

    func preset(named name: String) -> Preset? {
        presets.first { $0.name.caseInsensitiveCompare(name) == .orderedSame }
    }

    /// The auto-apply preset for exactly this set of connected displays.
    func autoPreset(for connected: [ConnectedDisplay]) -> Preset? {
        let current = Set(connected.map(\.uuid))
        return presets.first { $0.autoApply == true && $0.displaySet == current }
    }

    /// Toggles auto-apply; only one preset per display set can have it.
    func toggleAutoApply(named name: String) throws {
        guard let i = presets.firstIndex(where: { $0.name == name }) else { return }
        let enable = presets[i].autoApply != true
        for j in presets.indices where presets[j].displaySet == presets[i].displaySet {
            presets[j].autoApply = nil
        }
        presets[i].autoApply = enable ? true : nil
        try save()
    }

    /// Adds a preset, replacing an existing one with the same name (keeping its auto-apply flag).
    func upsert(_ preset: Preset) throws {
        if let i = presets.firstIndex(where: { $0.name.caseInsensitiveCompare(preset.name) == .orderedSame }) {
            var updated = preset
            if updated.displaySet == presets[i].displaySet {
                updated.autoApply = presets[i].autoApply
            }
            presets[i] = updated
        } else {
            presets.append(preset)
        }
        try save()
    }

    func remove(named name: String) throws {
        presets.removeAll { $0.name == name }
        try save()
    }

    private func save() throws {
        try FileManager.default.createDirectory(at: fileURL.deletingLastPathComponent(), withIntermediateDirectories: true)
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        try encoder.encode(presets).write(to: fileURL, options: .atomic)
    }
}
