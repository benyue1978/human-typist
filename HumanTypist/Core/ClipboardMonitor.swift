import AppKit

final class ClipboardMonitor {

    static let shared = ClipboardMonitor()

    private let pasteboard = NSPasteboard.general

    private init() {}

    func readText() -> String? {
        return pasteboard.string(forType: .string)
    }
}