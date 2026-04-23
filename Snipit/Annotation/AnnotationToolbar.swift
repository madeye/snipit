import AppKit

@MainActor
protocol AnnotationToolbarDelegate: AnyObject {
    func toolbarDidSelectText(_ toolbar: AnnotationToolbar)
    func toolbarDidChangeColor(_ toolbar: AnnotationToolbar, color: NSColor)
    func toolbarDidTapDone(_ toolbar: AnnotationToolbar)
    func toolbarDidTapCancel(_ toolbar: AnnotationToolbar)
}

final class AnnotationToolbar: NSPanel {
    weak var toolbarDelegate: AnnotationToolbarDelegate?

    private let textButton = NSButton()
    private let colorWell = NSColorWell()

    convenience init(attachedTo parentWindow: NSWindow) {
        let height: CGFloat = 44
        let width: CGFloat = 240
        let parentFrame = parentWindow.frame
        let origin = NSPoint(x: parentFrame.midX - width / 2,
                             y: parentFrame.maxY + 4)
        self.init(contentRect: NSRect(x: origin.x, y: origin.y, width: width, height: height),
                  styleMask: [.nonactivatingPanel, .titled, .closable],
                  backing: .buffered,
                  defer: false)
        title = ""
        isFloatingPanel = true
        becomesKeyOnlyIfNeeded = true
        isMovableByWindowBackground = true
        setupContent()
    }

    private func setupContent() {
        let stack = NSStackView()
        stack.orientation = .horizontal
        stack.spacing = 8
        stack.edgeInsets = NSEdgeInsets(top: 6, left: 12, bottom: 6, right: 12)
        stack.translatesAutoresizingMaskIntoConstraints = false

        // Text tool button
        textButton.title = "T"
        textButton.setButtonType(.toggle)
        textButton.bezelStyle = .rounded
        textButton.target = self
        textButton.action = #selector(textTapped)
        textButton.font = NSFont.boldSystemFont(ofSize: 14)
        textButton.widthAnchor.constraint(equalToConstant: 32).isActive = true

        // Color well
        colorWell.color = .systemRed
        colorWell.target = self
        colorWell.action = #selector(colorChanged)
        colorWell.widthAnchor.constraint(equalToConstant: 32).isActive = true

        // Done button
        let done = NSButton(title: "Done", target: self, action: #selector(doneTapped))
        done.bezelStyle = .rounded
        done.keyEquivalent = "\r"

        // Cancel button
        let cancel = NSButton(title: "Cancel", target: self, action: #selector(cancelTapped))
        cancel.bezelStyle = .rounded

        stack.addArrangedSubview(textButton)
        stack.addArrangedSubview(colorWell)
        stack.addArrangedSubview(NSView()) // spacer
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

    @objc private func textTapped() {
        toolbarDelegate?.toolbarDidSelectText(self)
    }

    @objc private func colorChanged() {
        toolbarDelegate?.toolbarDidChangeColor(self, color: colorWell.color)
    }

    @objc private func doneTapped() {
        toolbarDelegate?.toolbarDidTapDone(self)
    }

    @objc private func cancelTapped() {
        toolbarDelegate?.toolbarDidTapCancel(self)
    }

    var isTextActive: Bool {
        get { textButton.state == .on }
        set { textButton.state = newValue ? .on : .off }
    }
}
