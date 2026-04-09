import AppKit
import ServiceManagement

final class GeneralTab: NSView {

    private var loginToggle: NSButton!

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        setupUI()
        loadState()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupUI() {
        let stack = NSStackView()
        stack.orientation = .vertical
        stack.alignment = .leading
        stack.spacing = 16
        stack.translatesAutoresizingMaskIntoConstraints = false

        loginToggle = NSButton(checkboxWithTitle: "Start at Login", target: self, action: #selector(loginToggleChanged))
        stack.addArrangedSubview(loginToggle)

        let quitButton = NSButton(title: "Quit Human Typist", target: self, action: #selector(quitApp))
        quitButton.bezelStyle = .rounded
        stack.addArrangedSubview(quitButton)

        addSubview(stack)
        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: topAnchor, constant: 20),
            stack.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 20),
            stack.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -20)
        ])
    }

    private func loadState() {
        if #available(macOS 13.0, *) {
            loginToggle.state = SMAppService.mainApp.status == .enabled ? .on : .off
        } else {
            loginToggle.state = Preferences.shared.startAtLogin ? .on : .off
        }
    }

    @objc private func loginToggleChanged() {
        let enabled = loginToggle.state == .on
        Preferences.shared.startAtLogin = enabled
        if #available(macOS 13.0, *) {
            do {
                if enabled {
                    try SMAppService.mainApp.register()
                } else {
                    try SMAppService.mainApp.unregister()
                }
            } catch {
                print("Failed to update login item: \(error)")
            }
        }
    }

    @objc private func quitApp() {
        NSApp.terminate(nil)
    }
}
