import AppKit

final class ShortcutsTab: NSView {

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        setupUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupUI() {
        let stack = NSStackView()
        stack.orientation = .vertical
        stack.alignment = .leading
        stack.spacing = 12
        stack.translatesAutoresizingMaskIntoConstraints = false

        let shortcuts: [(String, String)] = [
            ("Start Typing", "⌃⌥P  (Ctrl+Alt+P)"),
            ("Stop Typing", "⌃⌥S  (Ctrl+Alt+S)"),
            ("Reload Clipboard", "⌃⌥R  (Ctrl+Alt+R)")
        ]

        for (action, keys) in shortcuts {
            let row = NSStackView()
            row.orientation = .horizontal
            row.spacing = 16

            let actionLabel = NSTextField(labelWithString: action)
            actionLabel.font = NSFont.systemFont(ofSize: 13, weight: .medium)
            actionLabel.setContentHuggingPriority(.defaultHigh, for: .horizontal)

            let keyLabel = NSTextField(labelWithString: keys)
            keyLabel.font = NSFont.monospacedSystemFont(ofSize: 13, weight: .regular)
            keyLabel.textColor = .secondaryLabelColor

            row.addArrangedSubview(actionLabel)
            row.addArrangedSubview(keyLabel)
            stack.addArrangedSubview(row)
        }

        let noteLabel = NSTextField(wrappingLabelWithString: "Hotkey rebinding is not available in v1.")
        noteLabel.font = NSFont.systemFont(ofSize: 11)
        noteLabel.textColor = .tertiaryLabelColor
        stack.addArrangedSubview(noteLabel)

        addSubview(stack)
        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: topAnchor, constant: 20),
            stack.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 20),
            stack.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -20)
        ])
    }
}
