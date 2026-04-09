import AppKit

class AppDelegate: NSObject, NSApplicationDelegate {

    private var statusBarController: StatusBarController?

    func applicationDidFinishLaunching(_ notification: Notification) {
        statusBarController = StatusBarController()

        HotkeyManager.shared.register(
            onStart: {
                NSLog("[AppDelegate] onStart callback fired, isRunning=%@", "\(TypingEngine.shared.isRunning)")
                let text = ClipboardMonitor.shared.readText() ?? ""
                NSLog("[AppDelegate] clipboard text: %d chars", text.count)
                guard !text.isEmpty else {
                    NSLog("[AppDelegate] clipboard empty, skipping")
                    return
                }
                TypingEngine.shared.start(text: text)
            },
            onStop: {
                TypingEngine.shared.stop()
            },
            onReload: {
                // clipboard is re-read on next start
            }
        )
    }

    func applicationWillTerminate(_ notification: Notification) {
        TypingEngine.shared.stop()
        HotkeyManager.shared.unregister()
    }
}
