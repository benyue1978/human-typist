import Foundation
import CoreGraphics
import Carbon

final class TypingEngine {

    static let shared = TypingEngine()

    private var typeThread: Thread?
    private var stopFlag = false
    private let lock = NSLock()

    private init() {}

    var isRunning: Bool {
        lock.lock()
        defer { lock.unlock() }
        return typeThread != nil && typeThread!.isExecuting
    }

    // MARK: - Public API

    func start(text: String) {
        lock.lock()
        guard typeThread == nil || !typeThread!.isExecuting else {
            lock.unlock()
            return
        }
        stopFlag = false
        typeThread = Thread { [weak self] in
            self?.humanType(text: text)
        }
        typeThread!.start()
        lock.unlock()
    }

    func stop() {
        lock.lock()
        stopFlag = true
        lock.unlock()
    }

    // MARK: - Timing Calculations

    func calcCharDelay(wpm: Double) -> Double {
        let cps = (wpm * 5.0) / 60.0
        let base = 1.0 / max(cps, 0.1)
        let jitter = Double.random(in: Preferences.shared.charJitterMin...Preferences.shared.charJitterMax)
        return base + jitter
    }

    func naturalPause(for ch: Character) -> Double {
        let str = String(ch)
        if [",", ";", ":"].contains(str) {
            let (min, max) = Preferences.shared.pauseAfterPunct
            return Double.random(in: min...max)
        }
        if [".", "!", "?"].contains(str) {
            let (min, max) = Preferences.shared.pauseAfterSentence
            return Double.random(in: min...max)
        }
        return 0
    }

    // MARK: - Private

    private func humanType(text: String) {
        let chars = Array(text)
        var idx = 0
        let n = chars.count

        while idx < n && !checkStop() {
            let burstWPM = Double.random(
                in: Double(Preferences.shared.wpmMin)...Double(Preferences.shared.wpmMax)
            )
            let burstEnd = Date().addingTimeInterval(
                Double.random(in: Preferences.shared.burstSecondsMin...Preferences.shared.burstSecondsMax)
            )

            while idx < n && Date() < burstEnd && !checkStop() {
                let ch = chars[idx]
                typeChar(ch)
                Thread.sleep(forTimeInterval: calcCharDelay(wpm: burstWPM))

                let pauseLen = naturalPause(for: ch)
                if pauseLen > 0 {
                    Thread.sleep(forTimeInterval: pauseLen)
                }
                maybeRandomPause()
                maybeThinkingPause()

                idx += 1
            }

            if idx < n && !checkStop() {
                Thread.sleep(forTimeInterval: Double.random(in: 0.05...0.2))
            }
        }
    }

    private func checkStop() -> Bool {
        lock.lock()
        let stopped = stopFlag
        lock.unlock()
        return stopped
    }

    private func maybeRandomPause() {
        guard Double.random(in: 0...1) < Preferences.shared.randomPauseChance else { return }
        Thread.sleep(forTimeInterval: Double.random(in: 0.05...0.08))
    }

    private func maybeThinkingPause() {
        guard Double.random(in: 0...1) < Preferences.shared.thinkingPauseChance else { return }
        let duration = Double.random(
            in: Preferences.shared.thinkingPauseMin...Preferences.shared.thinkingPauseMax
        )
        for _ in 0..<Int(duration * 10) {
            if checkStop() { break }
            Thread.sleep(forTimeInterval: 0.1)
        }
    }

    private func typeChar(_ ch: Character) {
        if ch == "\n" {
            postKey(keyCode: 0x24) // kVK_Return
        } else if ch == " " {
            postKey(keyCode: 0x31) // kVK_Space
        } else {
            postUnicode(String(ch))
        }
    }

    private func postKey(keyCode: UInt16) {
        let source = CGEventSource(stateID: .hidSystemState)

        guard let keyDown = CGEvent(keyboardEventSource: source, virtualKey: keyCode, keyDown: true) else { return }
        guard let keyUp = CGEvent(keyboardEventSource: source, virtualKey: keyCode, keyDown: false) else { return }

        keyDown.post(tap: .cghidEventTap)
        keyUp.post(tap: .cghidEventTap)
    }

    private func postUnicode(_ str: String) {
        let source = CGEventSource(stateID: .hidSystemState)
        let utf16 = Array(str.utf16)

        guard let keyDown = CGEvent(keyboardEventSource: source, virtualKey: 0, keyDown: true) else { return }
        guard let keyUp = CGEvent(keyboardEventSource: source, virtualKey: 0, keyDown: false) else { return }

        keyDown.keyboardSetUnicodeString(stringLength: utf16.count, unicodeString: utf16)
        keyUp.keyboardSetUnicodeString(stringLength: utf16.count, unicodeString: utf16)

        keyDown.post(tap: .cghidEventTap)
        keyUp.post(tap: .cghidEventTap)
    }
}
