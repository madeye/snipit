import Carbon

// Global trampoline — C callback can't capture Swift self
nonisolated(unsafe) var _hotKeyFire: (() -> Void)?

private let _hotKeyProc: EventHandlerProcPtr = { _, _, _ in
    DispatchQueue.main.async { _hotKeyFire?() }
    return noErr
}

final class HotKeyManager {
    var onHotKey: (() -> Void)? {
        didSet { _hotKeyFire = onHotKey }
    }

    private var hotKeyRef: EventHotKeyRef?
    private var handlerRef: EventHandlerRef?

    init() {
        var spec = EventTypeSpec(eventClass: OSType(kEventClassKeyboard),
                                 eventKind: UInt32(kEventHotKeyPressed))
        InstallEventHandler(GetApplicationEventTarget(), _hotKeyProc, 1, &spec, nil, &handlerRef)
    }

    func register(keyCode: UInt32, modifiers: UInt32) {
        if let ref = hotKeyRef { UnregisterEventHotKey(ref) }
        // Signature 'snip' as FourCharCode
        let sig: OSType = (UInt32(UInt8(ascii: "s")) << 24)
                        | (UInt32(UInt8(ascii: "n")) << 16)
                        | (UInt32(UInt8(ascii: "i")) << 8)
                        |  UInt32(UInt8(ascii: "p"))
        let id = EventHotKeyID(signature: sig, id: 1)
        RegisterEventHotKey(keyCode, modifiers, id, GetApplicationEventTarget(), 0, &hotKeyRef)
    }

    deinit {
        if let ref = hotKeyRef { UnregisterEventHotKey(ref) }
        if let ref = handlerRef { RemoveEventHandler(ref) }
    }
}
