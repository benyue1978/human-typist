import XCTest

final class HotkeyManagerTests: XCTestCase {

    func testRegister_hotkeysAreRegistered() {
        let manager = HotkeyManager.shared
        manager.register(
            onStart: { },
            onStop: { },
            onReload: { }
        )
        XCTAssertTrue(manager.isRegistered)
        manager.unregister()
    }

    func testUnregister_afterRegister() {
        let manager = HotkeyManager.shared
        manager.register(onStart: { }, onStop: { }, onReload: { })
        manager.unregister()
        XCTAssertFalse(manager.isRegistered)
    }
}