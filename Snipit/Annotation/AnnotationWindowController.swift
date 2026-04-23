import AppKit

@MainActor
final class AnnotationWindowController: NSWindowController, AnnotationCanvasDelegate, AnnotationToolbarDelegate {
    var onDone: ((CGImage) -> Void)?

    private var canvas: AnnotationCanvas!
    private var toolbar: AnnotationToolbar!

    init(image: CGImage) {
        // Scale down for display (Retina: pixel size ÷ 2)
        let scale = NSScreen.main?.backingScaleFactor ?? 2.0
        let displaySize = NSSize(width: CGFloat(image.width) / scale,
                                 height: CGFloat(image.height) / scale)

        let win = NSWindow(
            contentRect: NSRect(origin: .zero, size: displaySize),
            styleMask: [.borderless, .resizable],
            backing: .buffered,
            defer: false
        )
        win.isOpaque = true
        win.hasShadow = true
        win.level = .floating
        win.center()

        super.init(window: win)

        canvas = AnnotationCanvas(image: image)
        canvas.frame = NSRect(origin: .zero, size: displaySize)
        canvas.delegate = self
        win.contentView = canvas

        toolbar = AnnotationToolbar(attachedTo: win)
        toolbar.toolbarDelegate = self
        win.addChildWindow(toolbar, ordered: .above)
    }

    required init?(coder: NSCoder) { fatalError() }

    override func showWindow(_ sender: Any?) {
        super.showWindow(sender)
        toolbar.orderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    override func close() {
        toolbar.close()
        window?.close()
    }

    // MARK: AnnotationCanvasDelegate

    func canvasDone(_ canvas: AnnotationCanvas) {
        guard let img = canvas.renderToCGImage() else { return }
        onDone?(img)
    }

    func canvasCancel(_ canvas: AnnotationCanvas) {
        close()
    }

    // MARK: AnnotationToolbarDelegate

    func toolbarDidSelectText(_ toolbar: AnnotationToolbar) {
        canvas.isTextToolActive = toolbar.isTextActive
    }

    func toolbarDidChangeColor(_ toolbar: AnnotationToolbar, color: NSColor) {
        canvas.currentColor = color
    }

    func toolbarDidTapDone(_ toolbar: AnnotationToolbar) {
        canvasDone(canvas)
    }

    func toolbarDidTapCancel(_ toolbar: AnnotationToolbar) {
        close()
    }
}
