import XCTest

final class PreferencesTests: XCTestCase {

    override func setUp() {
        super.setUp()
        UserDefaults.standard.removeObject(forKey: Preferences.Keys.wpmMin)
    }

    func testWPMMinDefault() {
        XCTAssertEqual(Preferences.shared.wpmMin, 25)
    }

    func testWPMMinSetGet() {
        Preferences.shared.wpmMin = 40
        XCTAssertEqual(Preferences.shared.wpmMin, 40)
    }

    func testWPMMaxDefault() {
        XCTAssertEqual(Preferences.shared.wpmMax, 90)
    }

    func testPauseAfterPunctDefault() {
        let val = Preferences.shared.pauseAfterPunct
        XCTAssertEqual(val.0, 0.08, accuracy: 0.001)
        XCTAssertEqual(val.1, 0.70, accuracy: 0.001)
    }

    func testStartAtLoginDefault() {
        XCTAssertFalse(Preferences.shared.startAtLogin)
    }
}
