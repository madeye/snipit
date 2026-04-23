import AppKit

// Borderless NSWindow refuses to become key by default — override so keyboard events reach the view.
private final class KeyableWindow: NSWindow {
    override var canBecomeKey: Bool { true }
}

/// Manages the full-screen overlay window for region selection.
/// Completion receives the cropped CGImage + selection rect, or nil if cancelled.
final class SelectionOverlayController {
    private var window: NSWindow?
    private let screenshot: CGImage
    private let completion: ((CGImage, NSRect)?) -> Void

    init(screenshot: CGImage, completion: @escaping ((CGImage, NSRect)?) -> Void) {
        self.screenshot = screenshot
        self.completion = completion
    }

    func show() {
        guard let screen = NSScreen.main else {
            completion(nil)
            return
        }

        let win = KeyableWindow(
            contentRect: screen.frame,
            styleMask: .borderless,
            backing: .buffered,
            defer: false,
            screen: screen
        )
        win.level = NSWindow.Level(rawValue: Int(CGWindowLevelForKey(.screenSaverWindow)))
        win.isOpaque = false
        win.backgroundColor = .clear
        win.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        win.ignoresMouseEvents = false
        win.acceptsMouseMovedEvents = true

        let contentView = OverlayContentView(frame: screen.frame)
        contentView.screenshotImage = screenshot
        contentView.onConfirm = { [weak self] rect in
            self?.handleConfirm(rect: rect, screen: screen)
        }
        contentView.onCancel = { [weak self] in
            self?.dismiss(result: nil)
        }
        win.contentView = contentView

        self.window = win
        win.makeKeyAndOrderFront(nil)
        win.makeFirstResponder(contentView)
        NSApp.activate(ignoringOtherApps: true)
    }

    private func handleConfirm(rect: NSRect, screen: NSScreen) {
        let croppedImage = cropScreenshot(to: rect, screen: screen)
        dismiss(result: croppedImage.map { ($0, rect) })
    }

    private func cropScreenshot(to viewRect: NSRect, screen: NSScreen) -> CGImage? {
        let scale = screen.backingScaleFactor
        let screenHeight = screen.frame.height

        // Convert AppKit coords (bottom-left origin) → CGImage coords (top-left origin)
        let cgY = (screenHeight - viewRect.maxY) * scale
        let pixelRect = CGRect(
            x: viewRect.minX * scale,
            y: cgY,
            width: viewRect.width * scale,
            height: viewRect.height * scale
        )
        return screenshot.cropping(to: pixelRect)
    }

    private func dismiss(result: (CGImage, NSRect)?) {
        window?.orderOut(nil)
        window = nil
        completion(result)
    }
}
