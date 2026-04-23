import AppKit

@MainActor
protocol AnnotationCanvasDelegate: AnyObject {
    func canvasDone(_ canvas: AnnotationCanvas)
    func canvasCancel(_ canvas: AnnotationCanvas)
}

final class AnnotationCanvas: NSView {
    weak var delegate: AnnotationCanvasDelegate?
    var isTextToolActive = false
    var currentColor: NSColor = .systemRed
    var currentFontSize: CGFloat = 18

    private let image: CGImage
    private(set) var annotations: [TextAnnotation] = []
    private var activeTextField: NSTextField?

    init(image: CGImage) {
        self.image = image
        let size = NSSize(width: CGFloat(image.width), height: CGFloat(image.height))
        super.init(frame: NSRect(origin: .zero, size: size))
    }

    required init?(coder: NSCoder) { fatalError() }

    override var isFlipped: Bool { false }
    override var acceptsFirstResponder: Bool { true }

    // MARK: Drawing

    override func draw(_ dirtyRect: NSRect) {
        let nsImg = NSImage(cgImage: image, size: bounds.size)
        nsImg.draw(in: bounds)
        for annotation in annotations {
            annotation.draw()
        }
    }

    // MARK: Mouse

    override func mouseDown(with event: NSEvent) {
        commitActiveTextField()
        guard isTextToolActive else { return }
        let p = convert(event.locationInWindow, from: nil)
        placeTextField(at: p)
    }

    private func placeTextField(at point: NSPoint) {
        let field = NSTextField(frame: NSRect(x: point.x, y: point.y - currentFontSize, width: 200, height: currentFontSize + 8))
        field.font = NSFont.systemFont(ofSize: currentFontSize, weight: .semibold)
        field.textColor = currentColor
        field.backgroundColor = .clear
        field.isBordered = false
        field.isEditable = true
        field.placeholderString = "Type text..."
        field.target = self
        field.action = #selector(fieldCommit)
        addSubview(field)
        window?.makeFirstResponder(field)
        activeTextField = field
    }

    @objc private func fieldCommit() {
        commitActiveTextField()
    }

    func commitActiveTextField() {
        guard let field = activeTextField else { return }
        let text = field.stringValue.trimmingCharacters(in: .whitespacesAndNewlines)
        if !text.isEmpty {
            let origin = CGPoint(x: field.frame.minX, y: field.frame.minY)
            annotations.append(TextAnnotation(text: text, origin: origin,
                                              color: currentColor, fontSize: currentFontSize))
        }
        field.removeFromSuperview()
        activeTextField = nil
        needsDisplay = true
    }

    // MARK: Render to CGImage

    func renderToCGImage() -> CGImage? {
        commitActiveTextField()
        guard let bitmap = bitmapImageRepForCachingDisplay(in: bounds) else { return nil }
        cacheDisplay(in: bounds, to: bitmap)
        return bitmap.cgImage
    }
}
