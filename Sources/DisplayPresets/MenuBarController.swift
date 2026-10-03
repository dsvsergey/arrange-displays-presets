import AppKit
import ServiceManagement

final class MenuBarController: NSObject, NSMenuDelegate {
    private let store = PresetStore()
    private let statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
    private let menu = NSMenu()
    private var hotKeys: HotKeys?
    private var watcher: DisplayWatcher?
    private let keepAwake = KeepAwake()
    private var lastCycle = Date.distantPast

    override init() {
        super.init()
        updateIcon()
        menu.delegate = self
        menu.autoenablesItems = false
        statusItem.menu = menu

        hotKeys = HotKeys { [weak self] digit in self?.handleHotKey(digit) }
        hotKeys?.registerDigits()
        watcher = DisplayWatcher { [weak self] in self?.autoApplyIfNeeded() }
    }

    private func updateIcon() {
        // A cup marks that Keep Awake is on.
        let symbol = keepAwake.isEnabled ? "cup.and.saucer.fill" : "display.2"
        statusItem.button?.image = NSImage(systemSymbolName: symbol, accessibilityDescription: "Display Presets")
        statusItem.button?.image?.isTemplate = true
    }

    private static let hotKeyMask: NSEvent.ModifierFlags = [.control, .option, .command]

    // ⌃⌥⌘1…9 applies the preset at that position, ⌃⌥⌘0 cycles through available presets.
    private func handleHotKey(_ digit: UInt32) {
        store.load()
        let connected = Displays.connected()
        let target: Preset?
        if digit == 0 {
            // The menu key equivalent and the global hotkey may both fire for one press.
            guard Date().timeIntervalSince(lastCycle) > 0.5 else { return }
            lastCycle = Date()
            let available = store.presets.filter { $0.isAvailable(in: connected) }
            if let active = available.firstIndex(where: { $0.isActive(in: connected) }) {
                target = available[(active + 1) % available.count]
            } else {
                target = available.first
            }
        } else {
            let index = Int(digit) - 1
            target = index < store.presets.count ? store.presets[index] : nil
        }
        guard let preset = target, preset.isAvailable(in: connected) else {
            NSSound.beep()
            return
        }
        apply(preset)
    }

    private func autoApplyIfNeeded() {
        store.load()
        let connected = Displays.connected()
        guard let preset = store.autoPreset(for: connected), !preset.isActive(in: connected) else { return }
        try? Displays.apply(preset)
    }

    private func apply(_ preset: Preset) {
        do {
            try Displays.apply(preset)
        } catch {
            showError("Could not apply “\(preset.name)”", error)
        }
    }

    // Rebuild on every open so the list reflects connected displays and the current arrangement.
    func menuNeedsUpdate(_ menu: NSMenu) {
        menu.removeAllItems()
        store.load()
        let connected = Displays.connected()

        if store.presets.isEmpty {
            let hint = NSMenuItem(title: "No presets yet — arrange displays and save", action: nil, keyEquivalent: "")
            hint.isEnabled = false
            menu.addItem(hint)
        }

        for (index, preset) in store.presets.enumerated() {
            let key = index < 9 ? String(index + 1) : ""
            let title = preset.autoApply == true ? "\(preset.name)  ⚡︎" : preset.name
            let item = NSMenuItem(title: title, action: #selector(applyPreset(_:)), keyEquivalent: key)
            item.keyEquivalentModifierMask = Self.hotKeyMask
            item.target = self
            item.representedObject = preset.name
            item.image = PresetPreview.image(for: preset, connected: connected)
            item.state = preset.isActive(in: connected) ? .on : .off
            item.isEnabled = preset.isAvailable(in: connected)
            if !item.isEnabled {
                item.toolTip = "Some displays from this preset are not connected"
            }
            menu.addItem(item)
        }

        if store.presets.count > 1 {
            let next = NSMenuItem(title: "Next Preset", action: #selector(nextPreset), keyEquivalent: "0")
            next.keyEquivalentModifierMask = Self.hotKeyMask
            next.target = self
            menu.addItem(next)
        }

        menu.addItem(.separator())

        let save = NSMenuItem(title: "Save Current Arrangement…", action: #selector(saveCurrent), keyEquivalent: "s")
        save.target = self
        menu.addItem(save)

        if !store.presets.isEmpty {
            let autoItem = NSMenuItem(title: "Auto-apply on Connect", action: nil, keyEquivalent: "")
            let autoMenu = NSMenu()
            let autoHint = NSMenuItem(title: "Applied when exactly its displays connect", action: nil, keyEquivalent: "")
            autoHint.isEnabled = false
            autoMenu.addItem(autoHint)
            for preset in store.presets {
                let item = NSMenuItem(title: preset.name, action: #selector(toggleAutoApply(_:)), keyEquivalent: "")
                item.target = self
                item.representedObject = preset.name
                item.state = preset.autoApply == true ? .on : .off
                autoMenu.addItem(item)
            }
            autoItem.submenu = autoMenu
            menu.addItem(autoItem)

            let deleteItem = NSMenuItem(title: "Delete Preset", action: nil, keyEquivalent: "")
            let deleteMenu = NSMenu()
            for preset in store.presets {
                let item = NSMenuItem(title: preset.name, action: #selector(deletePreset(_:)), keyEquivalent: "")
                item.target = self
                item.representedObject = preset.name
                deleteMenu.addItem(item)
            }
            deleteItem.submenu = deleteMenu
            menu.addItem(deleteItem)
        }

        let openDisplays = NSMenuItem(title: "Open Displays Settings…", action: #selector(openDisplaySettings), keyEquivalent: "")
        openDisplays.target = self
        menu.addItem(openDisplays)

        menu.addItem(.separator())

        let awake = NSMenuItem(title: "Keep Mac Awake", action: #selector(toggleKeepAwake), keyEquivalent: "")
        awake.target = self
        awake.state = keepAwake.isEnabled ? .on : .off
        awake.toolTip = "Prevents the Mac and its displays from sleeping while idle"
        menu.addItem(awake)

        let login = NSMenuItem(title: "Launch at Login", action: #selector(toggleLaunchAtLogin(_:)), keyEquivalent: "")
        login.target = self
        login.state = SMAppService.mainApp.status == .enabled ? .on : .off
        menu.addItem(login)

        let quit = NSMenuItem(title: "Quit", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q")
        menu.addItem(quit)
    }

    @objc private func applyPreset(_ sender: NSMenuItem) {
        guard let name = sender.representedObject as? String, let preset = store.preset(named: name) else { return }
        apply(preset)
    }

    @objc private func nextPreset() {
        handleHotKey(0)
    }

    @objc private func toggleAutoApply(_ sender: NSMenuItem) {
        guard let name = sender.representedObject as? String else { return }
        do {
            try store.toggleAutoApply(named: name)
        } catch {
            showError("Could not change auto-apply", error)
        }
    }

    @objc private func saveCurrent() {
        NSApp.activate(ignoringOtherApps: true)
        let alert = NSAlert()
        alert.messageText = "Save Current Arrangement"
        alert.informativeText = "Existing preset with the same name will be overwritten."
        alert.addButton(withTitle: "Save")
        alert.addButton(withTitle: "Cancel")
        let field = NSTextField(frame: NSRect(x: 0, y: 0, width: 240, height: 24))
        field.placeholderString = "e.g. Laptop left of monitor"
        alert.accessoryView = field
        alert.window.initialFirstResponder = field

        guard alert.runModal() == .alertFirstButtonReturn else { return }
        let name = field.stringValue.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !name.isEmpty else { return }
        do {
            try store.upsert(.fromCurrent(named: name))
        } catch {
            showError("Could not save preset", error)
        }
    }

    @objc private func deletePreset(_ sender: NSMenuItem) {
        guard let name = sender.representedObject as? String else { return }
        do {
            try store.remove(named: name)
        } catch {
            showError("Could not delete preset", error)
        }
    }

    @objc private func openDisplaySettings() {
        if let url = URL(string: "x-apple.systempreferences:com.apple.Displays-Settings.extension") {
            NSWorkspace.shared.open(url)
        }
    }

    @objc private func toggleKeepAwake() {
        keepAwake.toggle()
        updateIcon()
    }

    @objc private func toggleLaunchAtLogin(_ sender: NSMenuItem) {
        do {
            if SMAppService.mainApp.status == .enabled {
                try SMAppService.mainApp.unregister()
            } else {
                try SMAppService.mainApp.register()
            }
        } catch {
            showError("Could not change Launch at Login", error)
        }
    }

    private func showError(_ title: String, _ error: Error) {
        NSApp.activate(ignoringOtherApps: true)
        let alert = NSAlert()
        alert.alertStyle = .warning
        alert.messageText = title
        alert.informativeText = error.localizedDescription
        alert.runModal()
    }
}
