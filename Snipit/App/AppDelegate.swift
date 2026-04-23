import AppKit

@NSApplicationMain
@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusItem: NSStatusItem!
    private let hotKeyManager = HotKeyManager()
    private var overlayController: SelectionOverlayController?
    private var annotationController: AnnotationWindowController?

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)
        setupStatusItem()
        setupHotKey()
        SettingsWindowController.shared.configure(hotKeyManager: hotKeyManager)
    }

    // MARK: Status Item

    private func setupStatusItem() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        if let button = statusItem.button {
            button.image = NSImage(systemSymbolName: "camera.viewfinder", accessibilityDescription: "Snipit")
            button.image?.isTemplate = true
        }

        let menu = NSMenu()
        menu.addItem(NSMenuItem(title: "Take Screenshot", action: #selector(takeScreenshot), keyEquivalent: ""))
        menu.addItem(.separator())
        menu.addItem(NSMenuItem(title: "Settings…", action: #selector(openSettings), keyEquivalent: ","))
        menu.addItem(.separator())
        menu.addItem(NSMenuItem(title: "Quit Snipit", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q"))
        statusItem.menu = menu
    }

    // MARK: Hot Key

    private func setupHotKey() {
        let prefs = PreferencesManager.shared
        hotKeyManager.register(keyCode: prefs.hotkeyKeyCode, modifiers: prefs.hotkeyModifiers)
        hotKeyManager.onHotKey = { [weak self] in
            self?.takeScreenshot()
        }
    }

    // MARK: Capture Flow

    @objc func takeScreenshot() {
        guard overlayController == nil else { return }
        Task { @MainActor in
            do {
                let image = try await ScreenCaptureEngine.captureMainDisplay()
                let controller = SelectionOverlayController(screenshot: image) { [weak self] result in
                    self?.overlayController = nil
                    guard let (cropped, _) = result else { return }
                    self?.showAnnotation(image: cropped)
                }
                overlayController = controller
                controller.show()
            } catch {
                showCaptureError(error)
            }
        }
    }

    private func showAnnotation(image: CGImage) {
        let controller = AnnotationWindowController(image: image)
        controller.onDone = { [weak self, weak controller] rendered in
            ClipboardExporter.export(image: rendered)
            controller?.close()
            self?.annotationController = nil
        }
        annotationController = controller
        controller.showWindow(nil)
    }

    private func showCaptureError(_ error: Error) {
        let alert = NSAlert()
        alert.messageText = "Screenshot Failed"
        alert.informativeText = error.localizedDescription
        alert.addButton(withTitle: "Open Privacy Settings")
        alert.addButton(withTitle: "OK")
        if alert.runModal() == .alertFirstButtonReturn {
            NSWorkspace.shared.open(URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_ScreenCapture")!)
        }
    }

    // MARK: Settings

    @objc func openSettings() {
        SettingsWindowController.shared.showWindow(nil)
        NSApp.activate(ignoringOtherApps: true)
    }
}
