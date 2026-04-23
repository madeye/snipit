import AppKit

// MARK: - Tool

enum AnnotationTool {
    case text, pencil, highlight
}

// MARK: - Annotation model

enum Annotation {
    case text(TextAnnotation)
    case path(PathAnnotation)

    func draw() {
        switch self {
        case .text(let t): t.draw()
        case .path(let p): p.draw()
        }
    }
}

// MARK: - Text

struct TextAnnotation {
    var text: String
    var origin: CGPoint
    var color: NSColor
    var fontSize: CGFloat

    func draw() {
        let attrs: [NSAttributedString.Key: Any] = [
            .font: NSFont.systemFont(ofSize: fontSize, weight: .semibold),
            .foregroundColor: color,
            .strokeColor: NSColor.black,
            .strokeWidth: -2.0,
        ]
        (text as NSString).draw(at: origin, withAttributes: attrs)
    }
}

// MARK: - Path (pencil / highlight)

struct PathAnnotation {
    var path: NSBezierPath
    var color: NSColor
    var lineWidth: CGFloat
    var isHighlight: Bool

    func draw() {
        NSGraphicsContext.saveGraphicsState()
        if isHighlight {
            // Multiply blending makes the highlight darker on light and lighter on dark
            NSGraphicsContext.current?.compositingOperation = .multiply
            color.withAlphaComponent(0.45).setStroke()
        } else {
            color.setStroke()
        }
        path.lineWidth = lineWidth
        path.lineCapStyle = .round
        path.lineJoinStyle = .round
        path.stroke()
        NSGraphicsContext.restoreGraphicsState()
    }
}
