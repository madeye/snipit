import AppKit

protocol AnnotationToolbarDelegate: AnyObject {
    func toolbar(_ toolbar: AnnotationToolbar, didSelectTool tool: AnnotationTool)
    func toolbarDidChangeColor(_ toolbar: AnnotationToolbar, color: NSColor)
    func toolbarDidTapDone(_ toolbar: AnnotationToolbar)
    func toolbarDidTapCancel(_ toolbar: AnnotationToolbar)
}

final class AnnotationToolbar: NSPanel {
    weak var toolbarDelegate: AnnotationToolbarDelegate?

    private let pencilButton   = AnnotationToolbar.toolButton(title: "✏️", tip: "Pencil")
    private let highlightButton = AnnotationToolbar.toolButton(title: "🖊", tip: "Highlighter")
    private let textButton     = AnnotationToolbar.toolButton(title: "T",  tip: "Text")
    private let colorWell      = NSColorWell()
    private var toolButtons: [NSButton] = []

    convenience init(attachedTo parentWindow: NSWindow) {
        let height: CGFloat = 48
        let width: CGFloat = 320
        let pf = parentWindow.frame
        self.init(
            contentRect: NSRect(x: pf.midX - width / 2, y: pf.maxY + 6, width: width, height: height),
            styleMask: [.nonactivatingPanel, .titled, .closable],
            backing: .buffered,
            defer: false
        )
        title = ""
        isFloatingPanel = true
        becomesKeyOnlyIfNeeded = true
        isMovableByWindowBackground = true
        toolButtons = [pencilButton, highlightButton, textButton]
        setupContent()
        selectTool(pencilButton)   // pencil active by default
    }

    private func setupContent() {
        let stack = NSStackView()
        stack.orientation = .horizontal
        stack.spacing = 6
        stack.edgeInsets = NSEdgeInsets(top: 6, left: 10, bottom: 6, right: 10)
        stack.translatesAutoresizingMaskIntoConstraints = false

        // Tool buttons
        for btn in toolButtons {
            btn.target = self
            btn.action = #selector(toolTapped(_:))
            stack.addArrangedSubview(btn)
        }

        // Separator
        let sep = NSBox(); sep.boxType = .separator
        sep.translatesAutoresizingMaskIntoConstraints = false
        sep.widthAnchor.constraint(equalToConstant: 1).isActive = true
        stack.addArrangedSubview(sep)

        // Color well
        colorWell.color = .systemRed
        colorWell.target = self
        colorWell.action = #selector(colorChanged)
        colorWell.widthAnchor.constraint(equalToConstant: 28).isActive = true
        colorWell.heightAnchor.constraint(equalToConstant: 28).isActive = true
        stack.addArrangedSubview(colorWell)

        // Spacer
        let spacer = NSView()
        spacer.setContentHuggingPriority(.defaultLow, for: .horizontal)
        stack.addArrangedSubview(spacer)

        // Cancel / Done
        let cancel = NSButton(title: "Cancel", target: self, action: #selector(cancelTapped))
        cancel.bezelStyle = .rounded
        let done = NSButton(title: "Done", target: self, action: #selector(doneTapped))
        done.bezelStyle = .rounded
        done.keyEquivalent = "\r"
        stack.addArrangedSubview(cancel)
        stack.addArrangedSubview(done)

        contentView?.addSubview(stack)
        NSLayoutConstraint.activate([
            stack.leadingAnchor.constraint(equalTo: contentView!.leadingAnchor),
            stack.trailingAnchor.constraint(equalTo: contentView!.trailingAnchor),
            stack.topAnchor.constraint(equalTo: contentView!.topAnchor),
            stack.bottomAnchor.constraint(equalTo: contentView!.bottomAnchor),
        ])
    }

    private static func toolButton(title: String, tip: String) -> NSButton {
        let b = NSButton()
        b.title = title
        b.toolTip = tip
        b.setButtonType(.toggle)
        b.bezelStyle = .rounded
        b.font = NSFont.systemFont(ofSize: 15)
        b.widthAnchor.constraint(equalToConstant: 36).isActive = true
        return b
    }

    private func selectTool(_ sender: NSButton) {
        for b in toolButtons { b.state = (b === sender) ? .on : .off }
    }

    @objc private func toolTapped(_ sender: NSButton) {
        selectTool(sender)
        let tool: AnnotationTool
        switch sender {
        case pencilButton:    tool = .pencil
        case highlightButton: tool = .highlight
        default:              tool = .text
        }
        toolbarDelegate?.toolbar(self, didSelectTool: tool)
    }

    @objc private func colorChanged() {
        toolbarDelegate?.toolbarDidChangeColor(self, color: colorWell.color)
    }

    @objc private func doneTapped()   { toolbarDelegate?.toolbarDidTapDone(self) }
    @objc private func cancelTapped() { toolbarDelegate?.toolbarDidTapCancel(self) }
}
