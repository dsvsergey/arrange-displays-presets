import Foundation

/// Command-line mode, handy for Shortcuts, Raycast or hotkey tools.
enum CLI {
    static let usage = """
    Usage:
      DisplayPresets                 start menu bar app
      DisplayPresets list            list saved presets
      DisplayPresets current         print connected displays and their origins
      DisplayPresets save <name>     save current arrangement as a preset
      DisplayPresets apply <name>    apply a saved preset
    """

    static func run(_ args: [String]) -> Int32 {
        let store = PresetStore()
        let name = args.dropFirst().joined(separator: " ")

        switch args.first {
        case "list":
            let connected = Displays.connected()
            for p in store.presets {
                let mark = p.isActive(in: connected) ? "*" : p.isAvailable(in: connected) ? " " : "-"
                print("\(mark) \(p.name)")
            }
            return 0
        case "current":
            for d in Displays.connected() {
                print("\(d.name)\t(\(Int(d.origin.x)), \(Int(d.origin.y)))\t\(d.uuid)")
            }
            return 0
        case "save" where !name.isEmpty:
            do {
                try store.upsert(.fromCurrent(named: name))
                print("Saved “\(name)”")
                return 0
            } catch {
                fputs("Error: \(error.localizedDescription)\n", stderr)
                return 1
            }
        case "apply" where !name.isEmpty:
            guard let preset = store.preset(named: name) else {
                fputs("No preset named “\(name)”\n", stderr)
                return 1
            }
            do {
                try Displays.apply(preset)
                return 0
            } catch {
                fputs("Error: \(error.localizedDescription)\n", stderr)
                return 1
            }
        default:
            print(usage)
            return args.first == "help" || args.first == "--help" ? 0 : 2
        }
    }
}
