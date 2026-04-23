import AppKit

final class AnnotationWindowController: NSWindowController, AnnotationCanvasDelegate, AnnotationToolbarDelegate {
    var onDone: ((CGImage) -> Void)?

    private var canvas: AnnotationCanvas!
    private var toolbar: AnnotationToolbar!

    init(image: CGImage) {
        let win = NSWindow(
            contentRect: .zero,
            styleMask: [.borderless, .resizable],
            backing: .buffered,
            defer: false
        )
        win.isOpaque = true
        win.hasShadow = true
        win.level = .floating
        super.init(window: win)

        canvas = AnnotationCanvas(image: image)
        win.contentView = canvas
        win.setContentSize(canvas.bounds.size)
        win.center()

        toolbar = AnnotationToolbar(attachedTo: win)
        toolbar.toolbarDelegate = self
        win.addChildWindow(toolbar, ordered: .above)
    }

    required init?(coder: NSCoder) { fatalError() }

    override func showWindow(_ sender: Any?) {
        super.showWindow(sender)
        toolbar.orderFront(nil)
        window?.makeFirstResponder(canvas)
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

    func toolbar(_ toolbar: AnnotationToolbar, didSelectTool tool: AnnotationTool) {
        canvas.currentTool = tool
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
