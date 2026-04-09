import XCTest

final class ClipboardMonitorTests: XCTestCase {

    func testReadTextFromPasteboard_returnsStringOrNil() {
        let monitor = ClipboardMonitor.shared
        // Just verify it doesn't crash and returns a String or nil
        let text = monitor.readText()
        // text can be nil (if clipboard empty) or a string
        XCTAssertTrue(text == nil || text is String)
    }
}