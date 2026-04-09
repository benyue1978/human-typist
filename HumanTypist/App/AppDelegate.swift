import AppKit

class AppDelegate: NSObject, NSApplicationDelegate {

    private var statusBarController: StatusBarController?

    func applicationDidFinishLaunching(_ notification: Notification) {
        statusBarController = StatusBarController()

        HotkeyManager.shared.register(
            onStart: {
                guard let text = ClipboardMonitor.shared.readText(), !text.isEmpty else { return }
                TypingEngine.shared.start(text: text)
            },
            onStop: {
                TypingEngine.shared.stop()
            },
            onReload: {
                // clipboard is read on start, nothing to reload
            }
        )
    }

    func applicationWillTerminate(_ notification: Notification) {
        TypingEngine.shared.stop()
        HotkeyManager.shared.unregister()
    }
}
