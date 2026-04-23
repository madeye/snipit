import AppKit
import Carbon

final class HotKeyRecorderView: NSView {
    var onChange: ((UInt32, UInt32) -> Void)?

    private(set) var keyCode: UInt32 = 0
    private(set) var modifiers: UInt32 = 0

    private let label = NSTextField(labelWithString: "Click to record…")
    private var isRecording = false
    private var monitor: Any?

    override init(frame: NSRect) {
        super.init(frame: frame)
        setup()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }

    private func setup() {
        wantsLayer = true
        layer?.cornerRadius = 6
        layer?.borderWidth = 1

        label.alignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        addSubview(label)
        NSLayoutConstraint.activate([
            label.centerXAnchor.constraint(equalTo: centerXAnchor),
            label.centerYAnchor.constraint(equalTo: centerYAnchor),
        ])
        updateAppearance()

        let click = NSClickGestureRecognizer(target: self, action: #selector(tapped))
        addGestureRecognizer(click)
    }

    func configure(keyCode: UInt32, modifiers: UInt32) {
        self.keyCode = keyCode
        self.modifiers = modifiers
        label.stringValue = displayString(keyCode: keyCode, modifiers: modifiers)
    }

    @objc private func tapped() {
        if isRecording { stopRecording() } else { startRecording() }
    }

    private func startRecording() {
        isRecording = true
        label.stringValue = "Press shortcut…"
        updateAppearance()
        monitor = NSEvent.addLocalMonitorForEvents(matching: [.keyDown, .flagsChanged]) { [weak self] event in
            self?.handleEvent(event)
            return nil
        }
    }

    private func stopRecording() {
        isRecording = false
        if let m = monitor { NSEvent.removeMonitor(m); monitor = nil }
        updateAppearance()
    }

    private func handleEvent(_ event: NSEvent) {
        guard event.type == .keyDown else { return }
        guard !event.modifierFlags.isEmpty else { return }

        let nsModifiers = event.modifierFlags.intersection([.command, .shift, .option, .control])
        guard !nsModifiers.isEmpty else { return }

        self.keyCode = UInt32(event.keyCode)
        self.modifiers = carbonModifiers(from: nsModifiers)
        label.stringValue = displayString(keyCode: self.keyCode, modifiers: self.modifiers)
        stopRecording()
        onChange?(self.keyCode, self.modifiers)
    }

    private func carbonModifiers(from flags: NSEvent.ModifierFlags) -> UInt32 {
        var m: UInt32 = 0
        if flags.contains(.command) { m |= UInt32(cmdKey) }
        if flags.contains(.shift)   { m |= UInt32(shiftKey) }
        if flags.contains(.option)  { m |= UInt32(optionKey) }
        if flags.contains(.control) { m |= UInt32(controlKey) }
        return m
    }

    private func displayString(keyCode: UInt32, modifiers: UInt32) -> String {
        var s = ""
        if modifiers & UInt32(controlKey) != 0 { s += "⌃" }
        if modifiers & UInt32(optionKey)  != 0 { s += "⌥" }
        if modifiers & UInt32(shiftKey)   != 0 { s += "⇧" }
        if modifiers & UInt32(cmdKey)     != 0 { s += "⌘" }
        s += keyName(for: keyCode)
        return s
    }

    private func keyName(for keyCode: UInt32) -> String {
        let map: [UInt32: String] = [
            0x00: "A", 0x01: "S", 0x02: "D", 0x03: "F", 0x04: "H", 0x05: "G",
            0x06: "Z", 0x07: "X", 0x08: "C", 0x09: "V", 0x0B: "B", 0x0C: "Q",
            0x0D: "W", 0x0E: "E", 0x0F: "R", 0x10: "Y", 0x11: "T", 0x12: "1",
            0x13: "2", 0x14: "3", 0x15: "4", 0x16: "6", 0x17: "5", 0x18: "=",
            0x19: "9", 0x1A: "7", 0x1B: "-", 0x1C: "8", 0x1D: "0", 0x1E: "]",
            0x1F: "O", 0x20: "U", 0x21: "[", 0x22: "I", 0x23: "P", 0x25: "L",
            0x26: "J", 0x27: "'", 0x28: "K", 0x29: ";", 0x2A: "\\", 0x2B: ",",
            0x2C: "/", 0x2D: "N", 0x2E: "M", 0x2F: ".", 0x32: "`",
            0x24: "↩", 0x30: "⇥", 0x31: "Space", 0x33: "⌫", 0x35: "⎋",
        ]
        return map[keyCode] ?? "Key\(keyCode)"
    }

    private func updateAppearance() {
        layer?.borderColor = isRecording ? NSColor.systemBlue.cgColor : NSColor.separatorColor.cgColor
        layer?.backgroundColor = isRecording ? NSColor.systemBlue.withAlphaComponent(0.1).cgColor : NSColor.controlBackgroundColor.cgColor
    }
}
