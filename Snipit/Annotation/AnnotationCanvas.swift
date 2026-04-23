import AppKit

protocol AnnotationCanvasDelegate: AnyObject {
    func canvasDone(_ canvas: AnnotationCanvas)
    func canvasCancel(_ canvas: AnnotationCanvas)
}

final class AnnotationCanvas: NSView, NSTextFieldDelegate {
    weak var delegate: AnnotationCanvasDelegate?

    var currentTool: AnnotationTool = .pencil
    var currentColor: NSColor = .systemRed
    var currentFontSize: CGFloat = 18

    private let image: CGImage
    private var annotations: [Annotation] = []

    // In-progress path (pencil / highlight)
    private var activePath: NSBezierPath?

    // In-progress text field
    private var activeTextField: NSTextField?

    init(image: CGImage) {
        self.image = image
        let scale = NSScreen.main?.backingScaleFactor ?? 2.0
        let displaySize = NSSize(width: CGFloat(image.width) / scale,
                                 height: CGFloat(image.height) / scale)
        super.init(frame: NSRect(origin: .zero, size: displaySize))
    }

    required init?(coder: NSCoder) { fatalError() }

    override var acceptsFirstResponder: Bool { true }
    override var isFlipped: Bool { false }

    // MARK: Drawing

    override func draw(_ dirtyRect: NSRect) {
        // Screenshot background
        NSImage(cgImage: image, size: bounds.size).draw(in: bounds)

        // Committed annotations
        for a in annotations { a.draw() }

        // Live path preview
        if let path = activePath {
            NSGraphicsContext.saveGraphicsState()
            if currentTool == .highlight {
                NSGraphicsContext.current?.compositingOperation = .multiply
                currentColor.withAlphaComponent(0.45).setStroke()
                path.lineWidth = highlightWidth
            } else {
                currentColor.setStroke()
                path.lineWidth = pencilWidth
            }
            path.lineCapStyle = .round
            path.lineJoinStyle = .round
            path.stroke()
            NSGraphicsContext.restoreGraphicsState()
        }
    }

    private var pencilWidth: CGFloat { 2.5 }
    private var highlightWidth: CGFloat { 16 }

    // MARK: Mouse events

    override func mouseDown(with event: NSEvent) {
        let p = convert(event.locationInWindow, from: nil)
        commitTextField()

        switch currentTool {
        case .text:
            placeTextField(at: p)
        case .pencil, .highlight:
            activePath = NSBezierPath()
            activePath?.move(to: p)
        }
    }

    override func mouseDragged(with event: NSEvent) {
        guard currentTool != .text, let path = activePath else { return }
        let p = convert(event.locationInWindow, from: nil)
        path.line(to: p)
        // Only redirty the bounding area for performance
        needsDisplay = true
    }

    override func mouseUp(with event: NSEvent) {
        guard currentTool != .text, let path = activePath else { return }
        let isHL = currentTool == .highlight
        let pa = PathAnnotation(
            path: path.copy() as! NSBezierPath,
            color: currentColor,
            lineWidth: isHL ? highlightWidth : pencilWidth,
            isHighlight: isHL
        )
        annotations.append(.path(pa))
        activePath = nil
        needsDisplay = true
    }

    // MARK: Text placement

    private func placeTextField(at point: NSPoint) {
        let field = NSTextField(frame: NSRect(x: point.x, y: point.y - currentFontSize - 4,
                                              width: 220, height: currentFontSize + 10))
        field.font = NSFont.systemFont(ofSize: currentFontSize, weight: .semibold)
        field.textColor = currentColor
        field.backgroundColor = NSColor.black.withAlphaComponent(0.08)
        field.drawsBackground = true
        field.isBordered = true
        field.isEditable = true
        field.isSelectable = true
        field.placeholderString = "Type, then press Return…"
        field.delegate = self
        field.target = self
        field.action = #selector(textFieldReturn)
        addSubview(field)
        window?.makeKeyAndOrderFront(nil)
        window?.makeFirstResponder(field)
        activeTextField = field
    }

    @objc private func textFieldReturn() {
        commitTextField()
    }

    func commitTextField() {
        guard let field = activeTextField else { return }
        let text = field.stringValue.trimmingCharacters(in: .whitespacesAndNewlines)
        if !text.isEmpty {
            let origin = CGPoint(x: field.frame.minX, y: field.frame.minY + 2)
            annotations.append(.text(TextAnnotation(text: text, origin: origin,
                                                    color: currentColor, fontSize: currentFontSize)))
        }
        field.removeFromSuperview()
        activeTextField = nil
        needsDisplay = true
    }

    // NSTextFieldDelegate — commit when field loses focus
    func controlTextDidEndEditing(_ obj: Notification) {
        commitTextField()
    }

    // MARK: Undo

    override func keyDown(with event: NSEvent) {
        if event.modifierFlags.contains(.command), event.keyCode == 6 { // Cmd+Z
            if !annotations.isEmpty {
                annotations.removeLast()
                needsDisplay = true
            }
        } else {
            super.keyDown(with: event)
        }
    }

    // MARK: Render

    func renderToCGImage() -> CGImage? {
        commitTextField()
        // Render at the actual pixel resolution of the original image
        let pixelSize = NSSize(width: CGFloat(image.width), height: CGFloat(image.height))
        guard let offscreen = NSImage(size: pixelSize, flipped: false, drawingHandler: { [self] rect in
            NSImage(cgImage: self.image, size: rect.size).draw(in: rect)
            let scale = pixelSize.width / self.bounds.width
            NSGraphicsContext.current?.cgContext.scaleBy(x: scale, y: scale)
            for a in self.annotations { a.draw() }
            return true
        }).cgImage(forProposedRect: nil, context: nil, hints: nil) else { return nil }
        return offscreen
    }
}
