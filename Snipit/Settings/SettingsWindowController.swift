import AppKit

final class SettingsWindowController: NSWindowController {
    static let shared = SettingsWindowController()

    private var recorder: HotKeyRecorderView?
    private weak var hotKeyManager: HotKeyManager?

    private convenience init() {
        let win = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 380, height: 220),
            styleMask: [.titled, .closable, .miniaturizable],
            backing: .buffered,
            defer: false
        )
        win.title = "Snipit Settings"
        win.center()
        self.init(window: win)
        buildUI()
    }

    override init(window: NSWindow?) { super.init(window: window) }
    required init?(coder: NSCoder) { fatalError() }

    func configure(hotKeyManager: HotKeyManager) {
        self.hotKeyManager = hotKeyManager
    }

    private func buildUI() {
        guard let cv = window?.contentView else { return }

        let prefs = PreferencesManager.shared

        // Shortcut row
        let shortcutLabel = NSTextField(labelWithString: "Screenshot Shortcut:")
        shortcutLabel.alignment = .right

        let recorderFrame = NSRect(x: 0, y: 0, width: 160, height: 28)
        let recorder = HotKeyRecorderView(frame: recorderFrame)
        recorder.configure(keyCode: prefs.hotkeyKeyCode, modifiers: prefs.hotkeyModifiers)
        recorder.onChange = { [weak self] keyCode, modifiers in
            prefs.hotkeyKeyCode = keyCode
            prefs.hotkeyModifiers = modifiers
            self?.hotKeyManager?.register(keyCode: keyCode, modifiers: modifiers)
        }
        self.recorder = recorder

        // Save to file row
        let saveCheck = NSButton(checkboxWithTitle: "Save screenshots to folder", target: self, action: #selector(saveToggled(_:)))
        saveCheck.state = prefs.saveToFile ? .on : .off

        // Close button
        let closeButton = NSButton(title: "Close", target: self, action: #selector(closeWindow))
        closeButton.bezelStyle = .rounded
        closeButton.keyEquivalent = "\u{1b}"

        // Layout using NSGridView
        let grid = NSGridView(views: [
            [shortcutLabel, recorder],
            [NSGridCell.emptyContentView, saveCheck],
            [NSGridCell.emptyContentView, closeButton],
        ])
        grid.column(at: 0).xPlacement = .trailing
        grid.rowSpacing = 16
        grid.columnSpacing = 12
        grid.translatesAutoresizingMaskIntoConstraints = false
        cv.addSubview(grid)

        NSLayoutConstraint.activate([
            grid.centerXAnchor.constraint(equalTo: cv.centerXAnchor),
            grid.centerYAnchor.constraint(equalTo: cv.centerYAnchor),
        ])
    }

    @objc private func saveToggled(_ sender: NSButton) {
        PreferencesManager.shared.saveToFile = sender.state == .on
    }

    @objc private func closeWindow() {
        window?.close()
    }
}
