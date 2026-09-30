import Carbon.HIToolbox

/// System-wide hotkeys via Carbon's RegisterEventHotKey (no Accessibility permission required).
final class HotKeys {
    /// Key codes for digits 0…9 (not sequential on the ANSI layout).
    static let digitKeyCodes: [UInt32] = [
        UInt32(kVK_ANSI_0), UInt32(kVK_ANSI_1), UInt32(kVK_ANSI_2), UInt32(kVK_ANSI_3), UInt32(kVK_ANSI_4),
        UInt32(kVK_ANSI_5), UInt32(kVK_ANSI_6), UInt32(kVK_ANSI_7), UInt32(kVK_ANSI_8), UInt32(kVK_ANSI_9),
    ]
    static let modifiers = UInt32(cmdKey | optionKey | controlKey)

    private var refs: [EventHotKeyRef] = []
    private var handlerRef: EventHandlerRef?
    private let onPress: (UInt32) -> Void

    init(onPress: @escaping (UInt32) -> Void) {
        self.onPress = onPress
        var spec = EventTypeSpec(eventClass: OSType(kEventClassKeyboard), eventKind: UInt32(kEventHotKeyPressed))
        InstallEventHandler(GetApplicationEventTarget(), { _, event, userData in
            guard let event, let userData else { return OSStatus(eventNotHandledErr) }
            var hotKeyID = EventHotKeyID()
            let status = GetEventParameter(event, EventParamName(kEventParamDirectObject), EventParamType(typeEventHotKeyID),
                                           nil, MemoryLayout<EventHotKeyID>.size, nil, &hotKeyID)
            guard status == noErr else { return status }
            Unmanaged<HotKeys>.fromOpaque(userData).takeUnretainedValue().onPress(hotKeyID.id)
            return noErr
        }, 1, &spec, Unmanaged.passUnretained(self).toOpaque(), &handlerRef)
    }

    /// Registers ⌃⌥⌘ + digit; the hotkey id equals the digit.
    func registerDigits() {
        for (digit, keyCode) in Self.digitKeyCodes.enumerated() {
            var ref: EventHotKeyRef?
            let id = EventHotKeyID(signature: OSType(0x4450_5253), id: UInt32(digit)) // 'DPRS'
            if RegisterEventHotKey(keyCode, Self.modifiers, id, GetApplicationEventTarget(), 0, &ref) == noErr, let ref {
                refs.append(ref)
            }
        }
    }

    deinit {
        refs.forEach { UnregisterEventHotKey($0) }
        if let handlerRef { RemoveEventHandler(handlerRef) }
    }
}
