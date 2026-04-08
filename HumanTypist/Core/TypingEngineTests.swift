import XCTest

final class TypingEngineTests: XCTestCase {

    func testCalcCharDelay_returnsPositiveValue() {
        let engine = TypingEngine.shared
        let delay = engine.calcCharDelay(wpm: 60)
        XCTAssertGreaterThan(delay, 0)
    }

    func testCalcCharDelay_higherWPM_fasterDelay() {
        let engine = TypingEngine.shared
        let delay60 = engine.calcCharDelay(wpm: 60)
        let delay30 = engine.calcCharDelay(wpm: 30)
        XCTAssertLessThan(delay60, delay30)
    }

    func testNaturalPauseFor_comma_returnsPositive() {
        let engine = TypingEngine.shared
        let pause = engine.naturalPause(for: ",")
        XCTAssertGreaterThan(pause, 0)
    }

    func testNaturalPauseFor_period_returnsPositive() {
        let engine = TypingEngine.shared
        let pause = engine.naturalPause(for: ".")
        XCTAssertGreaterThan(pause, 0)
    }

    func testNaturalPauseFor_space_returnsZero() {
        let engine = TypingEngine.shared
        let pause = engine.naturalPause(for: " ")
        XCTAssertEqual(pause, 0)
    }

    func testIsRunning_defaultFalse() {
        XCTAssertFalse(TypingEngine.shared.isRunning)
    }
}
