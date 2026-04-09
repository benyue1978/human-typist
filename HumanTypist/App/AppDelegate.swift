import AppKit

class AppDelegate: NSObject, NSApplicationDelegate {

    private var statusBarController: StatusBarController?

    func applicationDidFinishLaunching(_ notification: Notification) {
        statusBarController = StatusBarController()

        let ok = HotkeyManager.shared.register(
            onStart: {
                let text = ClipboardMonitor.shared.readText() ?? ""
                guard !text.isEmpty else { return }
                TypingEngine.shared.start(text: text)
            },
            onStop: {
                TypingEngine.shared.stop()
            }
        )

        if !ok {
            let alert = NSAlert()
            alert.messageText = "Accessibility Permission Required"
            alert.informativeText = "Human Typist needs Accessibility permission to detect hotkeys and type text. Please grant permission in System Settings > Privacy & Security > Accessibility, then relaunch the app."
            alert.alertStyle = .critical
            alert.addButton(withTitle: "Quit")
            alert.runModal()
            NSApp.terminate(nil)
        }
    }

    func applicationWillTerminate(_ notification: Notification) {
        TypingEngine.shared.stop()
        HotkeyManager.shared.unregister()
    }
}
