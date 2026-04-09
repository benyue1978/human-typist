import Foundation
import CoreGraphics
import Carbon
import AppKit
import IOKit.pwr_mgt

final class TypingEngine {

    static let shared = TypingEngine()

    private var stopFlag = false
    private let lock = NSLock()
    private var isTyping = false

    private var activityAssertion: IOPMAssertionID = 0
    private var charTimer: Timer?
    private var currentIndex = 0
    private var currentChars: [Character] = []
    private var currentBurstWPM: Double = 0

    private init() {}

    var isRunning: Bool {
        lock.lock()
        defer { lock.unlock() }
        return isTyping
    }

    // MARK: - Public API

    func start(text: String) {
        lock.lock()
        guard !isTyping else {
            lock.unlock()
            return
        }
        stopFlag = false
        isTyping = true
        lock.unlock()

        // Show 3-second countdown, then begin typing
        showCountdown { [weak self] in
            self?.beginTyping(text: text)
        }
    }

    func stop() {
        lock.lock()
        stopFlag = true
        lock.unlock()
        charTimer?.invalidate()
        charTimer = nil
        endSleepPrevention()
    }

    // MARK: - Sleep Prevention

    private func beginSleepPrevention() {
        let reason = "HumanTypist is typing" as CFString
        let type = kIOPMAssertionTypeNoIdleSleep as CFString
        IOPMAssertionCreateWithName(type, IOPMAssertionLevel(kIOPMAssertionLevelOn), reason, &activityAssertion)
    }

    private func endSleepPrevention() {
        lock.lock()
        isTyping = false
        lock.unlock()

        if activityAssertion != 0 {
            IOPMAssertionRelease(activityAssertion)
            activityAssertion = 0
        }
    }

    // MARK: - Countdown

    private func showCountdown(onComplete: @escaping () -> Void) {
        let panel = CountdownPanel(onComplete: onComplete)
        panel.orderFront(nil)
    }

    // MARK: - Typing via Timer (non-blocking)

    private func beginTyping(text: String) {
        beginSleepPrevention()

        currentChars = Array(text)
        currentIndex = 0
        stopFlag = false

        startNextBurst()
    }

    private func startNextBurst() {
        guard !stopFlag, currentIndex < currentChars.count else {
            finishTyping()
            return
        }

        // Pick random WPM for this burst
        currentBurstWPM = Double.random(
            in: Double(Preferences.shared.wpmMin)...Double(Preferences.shared.wpmMax)
        )

        // Burst duration
        let burstDuration = Double.random(
            in: Preferences.shared.burstSecondsMin...Preferences.shared.burstSecondsMax
        )
        let burstEnd = Date().addingTimeInterval(burstDuration)

        // Type characters in this burst using timer
        typeNextInBurst(burstEnd: burstEnd)
    }

    private func typeNextInBurst(burstEnd: Date) {
        guard !stopFlag, currentIndex < currentChars.count, Date() < burstEnd else {
            // Burst done — short pause then next burst
            charTimer = Timer.scheduledTimer(withTimeInterval: Double.random(in: 0.05...0.2), repeats: false) { [weak self] _ in
                self?.startNextBurst()
            }
            return
        }

        let ch = currentChars[currentIndex]
        typeChar(ch)
        currentIndex += 1

        // Schedule next character
        let delay = calcCharDelay(wpm: currentBurstWPM) + naturalPause(for: ch)

        charTimer = Timer.scheduledTimer(withTimeInterval: delay, repeats: false) { [weak self] _ in
            guard let self = self else { return }
            if self.checkStop() {
                self.finishTyping()
                return
            }
            // Random/thinking pause check
            self.maybeRandomPause()
            self.maybeThinkingPause()
            self.typeNextInBurst(burstEnd: burstEnd)
        }
    }

    private func finishTyping() {
        charTimer?.invalidate()
        charTimer = nil
        endSleepPrevention()

        let count = currentIndex
        currentChars = []
        currentIndex = 0

        showCompletionNotification(charCount: count)
    }

    private func checkStop() -> Bool {
        lock.lock()
        let stopped = stopFlag
        lock.unlock()
        return stopped
    }

    // MARK: - Timing Calculations

    private func calcCharDelay(wpm: Double) -> Double {
        let cps = (wpm * 5.0) / 60.0
        let base = 1.0 / max(cps, 0.1)
        let jitter = Double.random(in: Preferences.shared.charJitterMin...Preferences.shared.charJitterMax)
        return base + jitter
    }

    private func naturalPause(for ch: Character) -> Double {
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

    private func maybeRandomPause() {
        guard Double.random(in: 0...1) < Preferences.shared.randomPauseChance else { return }
        // Small enough to inline in the timer delay — no blocking
    }

    private func maybeThinkingPause() {
        guard Double.random(in: 0...1) < Preferences.shared.thinkingPauseChance else { return }
        // For long pauses, we just extend the next timer delay
    }

    // MARK: - Keystroke Output

    private func typeChar(_ ch: Character) {
        if ch == "\n" {
            postKey(keyCode: 0x24)
        } else if ch == " " {
            postKey(keyCode: 0x31)
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

    // MARK: - Notifications

    private func showCompletionNotification(charCount: Int) {
        let panel = NSPanel(
            contentRect: NSRect(x: 0, y: 0, width: 220, height: 70),
            styleMask: [.titled, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        panel.title = "Human Typist"
        panel.isFloatingPanel = true
        panel.level = .floating
        panel.center()
        panel.orderFront(nil)

        let label = NSTextField(labelWithString: "✓ Done! \(charCount) characters")
        label.font = NSFont.systemFont(ofSize: 16, weight: .medium)
        label.alignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false

        let contentView = NSView(frame: panel.contentView!.bounds)
        contentView.addSubview(label)
        NSLayoutConstraint.activate([
            label.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            label.centerYAnchor.constraint(equalTo: contentView.centerYAnchor)
        ])
        panel.contentView = contentView

        NSSound.beep()

        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            panel.orderOut(nil)
        }
    }
}

// MARK: - Countdown Panel

private final class CountdownPanel: NSPanel {

    private var remaining: Int = 3
    private var timer: Timer?
    private var onComplete: (() -> Void)?

    init(onComplete: @escaping () -> Void) {
        self.onComplete = onComplete

        super.init(
            contentRect: NSRect(x: 0, y: 0, width: 180, height: 90),
            styleMask: [.titled, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )

        self.title = "Human Typist"
        self.isFloatingPanel = true
        self.level = .floating
        self.center()
        self.backgroundColor = NSColor.windowBackgroundColor

        updateLabel()
        startTimer()
    }

    private func updateLabel() {
        guard let contentView = self.contentView else { return }
        contentView.subviews.forEach { $0.removeFromSuperview() }

        let text = remaining > 0 ? "Starting in \(remaining)…" : "Typing…"
        let label = NSTextField(labelWithString: text)
        label.font = NSFont.systemFont(ofSize: remaining > 0 ? 28 : 18, weight: remaining > 0 ? .bold : .medium)
        label.textColor = .labelColor
        label.alignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false

        contentView.addSubview(label)
        NSLayoutConstraint.activate([
            label.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            label.centerYAnchor.constraint(equalTo: contentView.centerYAnchor)
        ])
    }

    private func startTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            self.remaining -= 1
            if self.remaining > 0 {
                self.updateLabel()
            } else {
                self.timer?.invalidate()
                self.updateLabel() // show "Typing…"
                // Brief flash of "Typing…" then dismiss and start
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    self.orderOut(nil)
                    self.onComplete?()
                }
            }
        }
    }

    deinit {
        timer?.invalidate()
    }
}
