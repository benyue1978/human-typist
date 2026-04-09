import AppKit

final class StatusBarController {

    private var statusItem: NSStatusItem?
    private var panel: TypingPanel?

    init() {
        setupStatusItem()
    }

    private func setupStatusItem() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)

        if let button = statusItem?.button {
            button.image = NSImage(systemSymbolName: "keyboard", accessibilityDescription: "Human Typist")
            button.action = #selector(togglePanel)
            button.target = self
        }
    }

    @objc private func togglePanel() {
        if panel == nil {
            panel = TypingPanel()
        }
        panel!.toggle()
    }
}
