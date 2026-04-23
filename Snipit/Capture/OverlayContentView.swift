import AppKit

// Resize handle positions
private enum Handle: CaseIterable {
    case tl, tc, tr, ml, mr, bl, bc, br

    func cursor() -> NSCursor {
        switch self {
        case .ml, .mr: return .resizeLeftRight
        case .tc, .bc: return .resizeUpDown
        default:       return .arrow
        }
    }
}

/// Single full-screen view: screenshot backdrop, dim overlay with spotlight cutout,
/// selection rect, resize handles, and mouse event handling.
final class OverlayContentView: NSView {
    var screenshotImage: CGImage?
    var onConfirm: ((NSRect) -> Void)?
    var onCancel: (() -> Void)?

    private var selectionRect: NSRect = .zero
    private var dragStart: NSPoint = .zero
    private var activeHandle: Handle?
    private var isDraggingSelection = false
    private var dragOrigin: NSPoint = .zero
    private var dragSelectionOrigin: NSRect = .zero
    private let handleSize: CGFloat = 8
    private var isDrawing = false  // true while initial drag

    override var acceptsFirstResponder: Bool { true }
    override var isFlipped: Bool { false }

    // MARK: Drawing

    override func draw(_ dirtyRect: NSRect) {
        // 1. Screenshot backdrop
        if let img = screenshotImage {
            let nsImg = NSImage(cgImage: img, size: bounds.size)
            nsImg.draw(in: bounds)
        } else {
            NSColor.black.setFill()
            bounds.fill()
        }

        // 2. Dim with spotlight cutout using even-odd rule
        NSColor.black.withAlphaComponent(0.45).setFill()
        if selectionRect.isEmpty {
            bounds.fill()
        } else {
            let path = NSBezierPath(rect: bounds)
            path.windingRule = .evenOdd
            path.append(NSBezierPath(rect: selectionRect))
            path.fill()
        }

        guard !selectionRect.isEmpty else { return }

        // 3. Selection border
        NSColor.systemBlue.setStroke()
        let border = NSBezierPath(rect: selectionRect)
        border.lineWidth = 1.5
        border.stroke()

        // 4. Resize handles
        NSColor.white.setFill()
        NSColor.systemBlue.setStroke()
        for (_, center) in handleCenters() {
            let r = NSRect(x: center.x - handleSize / 2, y: center.y - handleSize / 2,
                           width: handleSize, height: handleSize)
            let p = NSBezierPath(ovalIn: r)
            p.lineWidth = 1.5
            p.fill()
            p.stroke()
        }

        // 5. Size label
        let label = "\(Int(selectionRect.width)) × \(Int(selectionRect.height))"
        let attrs: [NSAttributedString.Key: Any] = [
            .font: NSFont.monospacedDigitSystemFont(ofSize: 11, weight: .medium),
            .foregroundColor: NSColor.white,
        ]
        let labelSize = (label as NSString).size(withAttributes: attrs)
        var labelOrigin = NSPoint(x: selectionRect.midX - labelSize.width / 2,
                                  y: selectionRect.maxY + 6)
        // Keep on screen
        labelOrigin.y = min(labelOrigin.y, bounds.maxY - labelSize.height - 4)
        (label as NSString).draw(at: labelOrigin, withAttributes: attrs)
    }

    // MARK: Handle geometry

    private func handleCenters() -> [(Handle, NSPoint)] {
        let r = selectionRect
        return [
            (.tl, NSPoint(x: r.minX, y: r.maxY)),
            (.tc, NSPoint(x: r.midX, y: r.maxY)),
            (.tr, NSPoint(x: r.maxX, y: r.maxY)),
            (.ml, NSPoint(x: r.minX, y: r.midY)),
            (.mr, NSPoint(x: r.maxX, y: r.midY)),
            (.bl, NSPoint(x: r.minX, y: r.minY)),
            (.bc, NSPoint(x: r.midX, y: r.minY)),
            (.br, NSPoint(x: r.maxX, y: r.minY)),
        ]
    }

    private func handle(at point: NSPoint) -> Handle? {
        let half = handleSize / 2 + 2
        for (handle, center) in handleCenters() {
            let hr = NSRect(x: center.x - half, y: center.y - half, width: half * 2, height: half * 2)
            if hr.contains(point) { return handle }
        }
        return nil
    }

    // MARK: Mouse events

    override func mouseDown(with event: NSEvent) {
        let p = convert(event.locationInWindow, from: nil)

        // Double-click confirms selection
        if event.clickCount == 2, !selectionRect.isEmpty {
            onConfirm?(selectionRect)
            return
        }
        if !selectionRect.isEmpty, let h = handle(at: p) {
            activeHandle = h
            dragStart = p
            return
        }
        if !selectionRect.isEmpty, selectionRect.contains(p) {
            isDraggingSelection = true
            dragOrigin = p
            dragSelectionOrigin = selectionRect
            return
        }
        // Start new selection
        isDrawing = true
        activeHandle = nil
        isDraggingSelection = false
        dragStart = p
        selectionRect = .zero
        needsDisplay = true
    }

    override func mouseDragged(with event: NSEvent) {
        let p = convert(event.locationInWindow, from: nil)

        if let h = activeHandle {
            resizeSelection(handle: h, to: p)
        } else if isDraggingSelection {
            let delta = NSPoint(x: p.x - dragOrigin.x, y: p.y - dragOrigin.y)
            selectionRect = dragSelectionOrigin.offsetBy(dx: delta.x, dy: delta.y)
            selectionRect = selectionRect.intersection(bounds)
        } else if isDrawing {
            selectionRect = NSRect(x: min(dragStart.x, p.x),
                                   y: min(dragStart.y, p.y),
                                   width: abs(p.x - dragStart.x),
                                   height: abs(p.y - dragStart.y))
        }
        needsDisplay = true
    }

    override func mouseUp(with event: NSEvent) {
        activeHandle = nil
        isDraggingSelection = false
        isDrawing = false
        if selectionRect.width < 5 || selectionRect.height < 5 {
            selectionRect = .zero
            needsDisplay = true
        }
    }

    override func mouseExited(with event: NSEvent) {}

    override func cursorUpdate(with event: NSEvent) {
        let p = convert(event.locationInWindow, from: nil)
        if let h = handle(at: p) {
            h.cursor().set()
        } else if selectionRect.contains(p) {
            NSCursor.openHand.set()
        } else {
            NSCursor.crosshair.set()
        }
    }

    override func resetCursorRects() {
        addCursorRect(bounds, cursor: .crosshair)
    }

    // MARK: Keyboard

    override func keyDown(with event: NSEvent) {
        switch event.keyCode {
        case 53: // Escape
            onCancel?()
        case 36, 76: // Return / numpad Enter
            guard !selectionRect.isEmpty else { return }
            onConfirm?(selectionRect)
        default:
            super.keyDown(with: event)
        }
    }

    // MARK: Resize logic

    private func resizeSelection(handle: Handle, to p: NSPoint) {
        var r = selectionRect
        switch handle {
        case .tl: r = NSRect(x: p.x, y: r.minY, width: r.maxX - p.x, height: r.maxY - p.y).standardized
        case .tc: r = NSRect(x: r.minX, y: r.minY, width: r.width, height: p.y - r.minY).standardized
        case .tr: r = NSRect(x: r.minX, y: r.minY, width: p.x - r.minX, height: p.y - r.minY).standardized
        case .ml: r = NSRect(x: p.x, y: r.minY, width: r.maxX - p.x, height: r.height).standardized
        case .mr: r = NSRect(x: r.minX, y: r.minY, width: p.x - r.minX, height: r.height).standardized
        case .bl: r = NSRect(x: p.x, y: p.y, width: r.maxX - p.x, height: r.maxY - p.y).standardized
        case .bc: r = NSRect(x: r.minX, y: p.y, width: r.width, height: r.maxY - p.y).standardized
        case .br: r = NSRect(x: r.minX, y: p.y, width: p.x - r.minX, height: r.maxY - p.y).standardized
        }
        selectionRect = r.intersection(bounds)
    }
}

private extension NSRect {
    func offsetBy(dx: CGFloat, dy: CGFloat) -> NSRect {
        NSRect(x: minX + dx, y: minY + dy, width: width, height: height)
    }
}
