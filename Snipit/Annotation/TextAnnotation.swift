import AppKit

struct TextAnnotation {
    var text: String
    var origin: CGPoint      // in view points, bottom-left
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
