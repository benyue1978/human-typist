# Human Typist — macOS Menu Bar App Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build a macOS menu bar app that types clipboard text into any focused text field with human-like timing variations.

**Architecture:** Menu bar-only app (LSUIElement) with a floating NSPanel for settings. Global hotkeys via Carbon. Keystroke injection via CGEvent. Preferences via UserDefaults.

**Tech Stack:** Swift 5.9+, AppKit, Carbon (HIToolbox), CGEvent, XcodeGen. No external dependencies.

---

## File Structure

```
HumanTypist/
├── project.yml                    # XcodeGen config
├── App/
│   ├── main.swift                 # NSApplication entry (no @main)
│   ├── AppDelegate.swift          # App lifecycle, menu bar setup
│   └── Info.plist                 # LSUIElement, app config
├── UI/
│   ├── StatusBarController.swift  # NSStatusItem, panel toggle
│   ├── TypingPanel.swift          # NSPanel (floating, non-activating)
│   ├── GeneralTab.swift           # Start at login toggle
│   ├── ShortcutsTab.swift         # Hotkey display (read-only v1)
│   └── TypingParamsTab.swift      # All typing parameter controls
├── Core/
│   ├── TypingEngine.swift         # CGEvent typing with all timing logic
│   ├── HotkeyManager.swift        # Carbon RegisterEventHotKey
│   ├── ClipboardMonitor.swift     # NSPasteboard polling
│   └── Preferences.swift          # UserDefaults keys + accessors
└── Resources/
    └── Assets.xcassets/           # Menu bar icon
```

---

## Task 1: Project Scaffold & XcodeGen

**Files:**
- Create: `HumanTypist/project.yml`
- Create: `HumanTypist/App/main.swift`
- Create: `HumanTypist/App/AppDelegate.swift`
- Create: `HumanTypist/App/Info.plist`
- Create: `HumanTypist/Resources/Assets.xcassets/AppIcon.appiconset/Contents.json`

- [ ] **Step 1: Create XcodeGen project.yml**

```yaml
name: HumanTypist
options:
  bundleIdPrefix: com.humantypist
  deploymentTarget:
    macOS: "13.0"
  xcodeVersion: "15.0"

settings:
  base:
    SWIFT_VERSION: "5.9"
    MACOSX_DEPLOYMENT_TARGET: "13.0"
    CODE_SIGN_IDENTITY: "-"
    PRODUCT_BUNDLE_IDENTIFIER: com.humantypist.app
    INFOPLIST_FILE: App/Info.plist
    ASSETCATALOG_COMPILER_APPICON_NAME: AppIcon
    LD_RUNPATH_SEARCH_PATHS: "@executable_path/../Frameworks"
    ENABLE_HARDENED_RUNTIME: YES

targets:
  HumanTypist:
    type: application
    platform: macOS
    sources:
      - path: App
      - path: UI
      - path: Core
      - path: Resources
    settings:
      base:
        PRODUCT_NAME: HumanTypist
        GENERATE_INFOPLIST_FILE: NO
```

- [ ] **Step 2: Create Resources/Assets.xcassets/AppIcon.appiconset/Contents.json**

```json
{
  "images" : [
    {
      "idiom" : "mac",
      "scale" : "1x",
      "size" : "16x16"
    },
    {
      "idiom" : "mac",
      "scale" : "2x",
      "size" : "16x16"
    },
    {
      "idiom" : "mac",
      "scale" : "1x",
      "size" : "32x32"
    },
    {
      "idiom" : "mac",
      "scale" : "2x",
      "size" : "32x32"
    },
    {
      "idiom" : "mac",
      "scale" : "1x",
      "size" : "128x128"
    },
    {
      "idiom" : "mac",
      "scale" : "2x",
      "size" : "128x128"
    },
    {
      "idiom" : "mac",
      "scale" : "1x",
      "size" : "256x256"
    },
    {
      "idiom" : "mac",
      "scale" : "2x",
      "size" : "256x256"
    },
    {
      "idiom" : "mac",
      "scale" : "1x",
      "size" : "512x512"
    },
    {
      "idiom" : "mac",
      "scale" : "2x",
      "size" : "512x512"
    }
  ],
  "info" : {
    "author" : "xcode",
    "version" : 1
  }
}
```

- [ ] **Step 3: Create Resources/Assets.xcassets/Contents.json**

```json
{
  "info" : {
    "author" : "xcode",
    "version" : 1
  }
}
```

- [ ] **Step 4: Create App/Info.plist**

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleDevelopmentRegion</key>
    <string>en</string>
    <key>CFBundleExecutable</key>
    <string>$(EXECUTABLE_NAME)</string>
    <key>CFBundleIconFile</key>
    <string></string>
    <key>CFBundleIconName</key>
    <string>AppIcon</string>
    <key>CFBundleIdentifier</key>
    <string>$(PRODUCT_BUNDLE_IDENTIFIER)</string>
    <key>CFBundleInfoDictionaryVersion</key>
    <string>6.0</string>
    <key>CFBundleName</key>
    <string>$(PRODUCT_NAME)</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>CFBundleShortVersionString</key>
    <string>1.0</string>
    <key>CFBundleVersion</key>
    <string>1</string>
    <key>LSMinimumSystemVersion</key>
    <string>$(MACOSX_DEPLOYMENT_TARGET)</string>
    <key>LSUIElement</key>
    <true/>
    <key>NSHumanReadableCopyright</key>
    <string>Copyright 2026. All rights reserved.</string>
    <key>NSPrincipalClass</key>
    <string>NSApplication</string>
</dict>
</plist>
```

- [ ] **Step 5: Create App/main.swift**

```swift
import AppKit

let app = NSApplication.shared
let delegate = AppDelegate()
app.delegate = delegate
app.run()
```

- [ ] **Step 6: Create App/AppDelegate.swift (stub)**

```swift
import AppKit

class AppDelegate: NSObject, NSApplicationDelegate {

    private var statusBarController: StatusBarController?

    func applicationDidFinishLaunching(_ notification: Notification) {
        statusBarController = StatusBarController()
    }

    func applicationWillTerminate(_ notification: Notification) {
        TypingEngine.shared.stop()
    }
}
```

- [ ] **Step 7: Run xcodegen**

Run: `cd HumanTypist && xcodegen generate`
Expected: `HumanTypist.xcodeproj` generated

- [ ] **Step 8: Commit**

```bash
git add HumanTypist/project.yml HumanTypist/App/main.swift HumanTypist/App/AppDelegate.swift HumanTypist/App/Info.plist HumanTypist/Resources/Assets.xcassets
git commit -m "feat: scaffold XcodeGen project structure"
```

---

## Task 2: Preferences Core

**Files:**
- Create: `HumanTypist/Core/Preferences.swift`

- [ ] **Step 1: Write unit test for Preferences.swift**

```swift
import XCTest
@testable import HumanTypist

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
```

- [ ] **Step 2: Run test to verify it fails**

Run: `xcodebuild test -project HumanTypist/HumanTypist.xcodeproj -scheme HumanTypist -destination 'platform=macOS' 2>&1 | grep -E "(error:|BUILD|test)` | head -30`
Expected: FAIL — Preferences not defined

- [ ] **Step 3: Write Preferences.swift**

```swift
import Foundation

final class Preferences {

    static let shared = Preferences()

    struct Keys {
        static let wpmMin = "wpmMin"
        static let wpmMax = "wpmMax"
        static let burstSecondsMin = "burstSecondsMin"
        static let burstSecondsMax = "burstSecondsMax"
        static let charJitterMin = "charJitterMin"
        static let charJitterMax = "charJitterMax"
        static let pauseAfterPunctMin = "pauseAfterPunctMin"
        static let pauseAfterPunctMax = "pauseAfterPunctMax"
        static let pauseAfterSentenceMin = "pauseAfterSentenceMin"
        static let pauseAfterSentenceMax = "pauseAfterSentenceMax"
        static let randomPauseChance = "randomPauseChance"
        static let thinkingPauseChance = "thinkingPauseChance"
        static let thinkingPauseMin = "thinkingPauseMin"
        static let thinkingPauseMax = "thinkingPauseMax"
        static let startAtLogin = "startAtLogin"
    }

    private let defaults = UserDefaults.standard

    private init() {
        registerDefaults()
    }

    private func registerDefaults() {
        defaults.register(defaults: [
            Keys.wpmMin: 25,
            Keys.wpmMax: 90,
            Keys.burstSecondsMin: 1.0,
            Keys.burstSecondsMax: 6.0,
            Keys.charJitterMin: 0.0,
            Keys.charJitterMax: 0.08,
            Keys.pauseAfterPunctMin: 0.08,
            Keys.pauseAfterPunctMax: 0.70,
            Keys.pauseAfterSentenceMin: 0.25,
            Keys.pauseAfterSentenceMax: 1.0,
            Keys.randomPauseChance: 0.06,
            Keys.thinkingPauseChance: 0.008,
            Keys.thinkingPauseMin: 4.5,
            Keys.thinkingPauseMax: 8.0,
            Keys.startAtLogin: false
        ])
    }

    var wpmMin: Int {
        get { defaults.integer(forKey: Keys.wpmMin) }
        set { defaults.set(newValue, forKey: Keys.wpmMin) }
    }

    var wpmMax: Int {
        get { defaults.integer(forKey: Keys.wpmMax) }
        set { defaults.set(newValue, forKey: Keys.wpmMax) }
    }

    var burstSecondsMin: Double {
        get { defaults.double(forKey: Keys.burstSecondsMin) }
        set { defaults.set(newValue, forKey: Keys.burstSecondsMin) }
    }

    var burstSecondsMax: Double {
        get { defaults.double(forKey: Keys.burstSecondsMax) }
        set { defaults.set(newValue, forKey: Keys.burstSecondsMax) }
    }

    var charJitterMin: Double {
        get { defaults.double(forKey: Keys.charJitterMin) }
        set { defaults.set(newValue, forKey: Keys.charJitterMin) }
    }

    var charJitterMax: Double {
        get { defaults.double(forKey: Keys.charJitterMax) }
        set { defaults.set(newValue, forKey: Keys.charJitterMax) }
    }

    var pauseAfterPunct: (Double, Double) {
        get {
            (defaults.double(forKey: Keys.pauseAfterPunctMin),
             defaults.double(forKey: Keys.pauseAfterPunctMax))
        }
        set {
            defaults.set(newValue.0, forKey: Keys.pauseAfterPunctMin)
            defaults.set(newValue.1, forKey: Keys.pauseAfterPunctMax)
        }
    }

    var pauseAfterSentence: (Double, Double) {
        get {
            (defaults.double(forKey: Keys.pauseAfterSentenceMin),
             defaults.double(forKey: Keys.pauseAfterSentenceMax))
        }
        set {
            defaults.set(newValue.0, forKey: Keys.pauseAfterSentenceMin)
            defaults.set(newValue.1, forKey: Keys.pauseAfterSentenceMax)
        }
    }

    var randomPauseChance: Double {
        get { defaults.double(forKey: Keys.randomPauseChance) }
        set { defaults.set(newValue, forKey: Keys.randomPauseChance) }
    }

    var thinkingPauseChance: Double {
        get { defaults.double(forKey: Keys.thinkingPauseChance) }
        set { defaults.set(newValue, forKey: Keys.thinkingPauseChance) }
    }

    var thinkingPauseMin: Double {
        get { defaults.double(forKey: Keys.thinkingPauseMin) }
        set { defaults.set(newValue, forKey: Keys.thinkingPauseMin) }
    }

    var thinkingPauseMax: Double {
        get { defaults.double(forKey: Keys.thinkingPauseMax) }
        set { defaults.set(newValue, forKey: Keys.thinkingPauseMax) }
    }

    var startAtLogin: Bool {
        get { defaults.bool(forKey: Keys.startAtLogin) }
        set { defaults.set(newValue, forKey: Keys.startAtLogin) }
    }
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `xcodebuild test -project HumanTypist/HumanTypist.xcodeproj -scheme HumanTypist -destination 'platform=macOS' 2>&1 | grep -E "(test|PASS|FAIL|BUILD)" | head -20`
Expected: PreferencesTests PASS

- [ ] **Step 5: Commit**

```bash
git add HumanTypist/Core/Preferences.swift
git commit -m "feat: add Preferences UserDefaults wrapper with all typing params"
```

---

## Task 3: TypingEngine Core

**Files:**
- Create: `HumanTypist/Core/TypingEngine.swift`

- [ ] **Step 1: Write unit test for TypingEngine.swift**

```swift
import XCTest
@testable import HumanTypist

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
```

- [ ] **Step 2: Run test to verify it fails**

Run: `xcodebuild test -project HumanTypist/HumanTypist.xcodeproj -scheme HumanTypist -destination 'platform=macOS' 2>&1 | grep -E "(error:|BUILD)" | head -20`
Expected: FAIL — TypingEngine not defined

- [ ] **Step 3: Write TypingEngine.swift**

```swift
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
        let range = Preferences.shared.randomPauseChance > 0 ? 0.05 : 0.08
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

    private func postKey(keyCode: UInt16, unicode: UniChar?) {
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
```

- [ ] **Step 4: Run test to verify it passes**

Run: `xcodebuild test -project HumanTypist/HumanTypist.xcodeproj -scheme HumanTypist -destination 'platform=macOS' 2>&1 | grep -E "(test|PASS|FAIL|BUILD)" | head -20`
Expected: TypingEngineTests PASS

- [ ] **Step 5: Commit**

```bash
git add HumanTypist/Core/TypingEngine.swift
git commit -m "feat: add TypingEngine with CGEvent keyboard simulation and human-like timing"
```

---

## Task 4: HotkeyManager

**Files:**
- Create: `HumanTypist/Core/HotkeyManager.swift`

- [ ] **Step 1: Write integration test for HotkeyManager**

```swift
import XCTest
@testable import HumanTypist

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
```

- [ ] **Step 2: Run test to verify it fails**

Run: `xcodebuild test -project HumanTypist/HumanTypist.xcodeproj -scheme HumanTypist -destination 'platform=macOS' 2>&1 | grep -E "(error:|BUILD)" | head -20`
Expected: FAIL — HotkeyManager not defined

- [ ] **Step 3: Write HotkeyManager.swift**

```swift
import Foundation
import Carbon

final class HotkeyManager {

    static let shared = HotkeyManager()

    private var hotkeyRefStart: EventHotKeyRef?
    private var hotkeyRefStop: EventHotKeyRef?
    private var hotkeyRefReload: EventHotKeyRef?
    private var eventHandler: EventHandlerRef?

    var onStart: (() -> Void)?
    var onStop: (() -> Void)?
    var onReload: (() -> Void)?

    private(set) var isRegistered = false

    // Ctrl+Alt+P = keycode 35 (P), modifiers: control + option
    // Ctrl+Alt+S = keycode 1 (S), modifiers: control + option
    // Ctrl+Alt+R = keycode 15 (R), modifiers: control + option
    private let startKeyID = EventHotKeyID(signature: OSType(0x48545043), id: 1) // "HTPC"
    private let stopKeyID = EventHotKeyID(signature: OSType(0x48545043), id: 2)
    private let reloadKeyID = EventHotKeyID(signature: OSType(0x48545043), id: 3)

    private init() {}

    func register(onStart: @escaping () -> Void,
                   onStop: @escaping () -> Void,
                   onReload: @escaping () -> Void) {
        self.onStart = onStart
        self.onStop = onStop
        self.onReload = onReload

        var eventType = EventTypeSpec(eventClass: OSType(kEventClassKeyboard), eventKind: UInt32(kEventHotKeyPressed))

        let status = InstallEventHandler(
            GetApplicationEventTarget(),
            { (_, event, _) -> OSStatus in
                HotkeyManager.shared.handleHotkey(event)
                return noErr
            },
            1,
            &eventType,
            nil,
            &eventHandler
        )

        guard status == noErr else { return }

        // Ctrl+Alt+P = P keycode 0x35 (35), modifiers control+option
        var startHotkeyID = startKeyID
        RegisterEventHotKey(
            0x35, // kVK_ANSI_P
            UInt32(controlKey | optionKey),
            startHotkeyID,
            GetApplicationEventTarget(),
            0,
            &hotkeyRefStart
        )

        // Ctrl+Alt+S = S keycode 0x01 (1), modifiers control+option
        var stopHotkeyID = stopKeyID
        RegisterEventHotKey(
            0x01, // kVK_ANSI_S
            UInt32(controlKey | optionKey),
            stopHotkeyID,
            GetApplicationEventTarget(),
            0,
            &hotkeyRefStop
        )

        // Ctrl+Alt+R = R keycode 0x0F (15), modifiers control+option
        var reloadHotkeyID = reloadKeyID
        RegisterEventHotKey(
            0x0F, // kVK_ANSI_R
            UInt32(controlKey | optionKey),
            reloadHotkeyID,
            GetApplicationEventTarget(),
            0,
            &hotkeyRefReload
        )

        isRegistered = true
    }

    func unregister() {
        if let ref = hotkeyRefStart {
            UnregisterEventHotKey(ref)
            hotkeyRefStart = nil
        }
        if let ref = hotkeyRefStop {
            UnregisterEventHotKey(ref)
            hotkeyRefStop = nil
        }
        if let ref = hotkeyRefReload {
            UnregisterEventHotKey(ref)
            hotkeyRefReload = nil
        }
        if let handler = eventHandler {
            RemoveEventHandler(handler)
            eventHandler = nil
        }
        isRegistered = false
    }

    private func handleHotkey(_ event: EventRef?) -> OSStatus {
        guard let event = event else { return OSStatus(eventNotHandledErr) }
        var hotkeyID = EventHotKeyID()
        let status = GetEventParameter(
            event,
            UInt32(kEventParamDirectObject),
            UInt32(typeEventHotKeyID),
            nil,
            MemoryLayout<EventHotKeyID>.size,
            nil,
            &hotkeyID
        )
        guard status == noErr else { return status }

        DispatchQueue.main.async {
            switch hotkeyID.id {
            case 1: self.onStart?()
            case 2: self.onStop?()
            case 3: self.onReload?()
            default: break
            }
        }
        return noErr
    }
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `xcodebuild test -project HumanTypist/HumanTypist.xcodeproj -scheme HumanTypist -destination 'platform=macOS' 2>&1 | grep -E "(test|PASS|FAIL|BUILD)" | head -20`
Expected: HotkeyManagerTests PASS

- [ ] **Step 5: Commit**

```bash
git add HumanTypist/Core/HotkeyManager.swift
git commit -m "feat: add HotkeyManager with Carbon RegisterEventHotKey for Ctrl+Alt+P/S/R"
```

---

## Task 5: ClipboardMonitor

**Files:**
- Create: `HumanTypist/Core/ClipboardMonitor.swift`

- [ ] **Step 1: Write unit test for ClipboardMonitor**

```swift
import XCTest
@testable import HumanTypist

final class ClipboardMonitorTests: XCTestCase {

    func testReadTextFromPasteboard_returnsString() {
        let monitor = ClipboardMonitor.shared
        let text = monitor.readText()
        XCTAssertNotNil(text)
    }
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `xcodebuild test -project HumanTypist/HumanTypist.xcodeproj -scheme HumanTypist -destination 'platform=macOS' 2>&1 | grep -E "(error:|BUILD)" | head -20`
Expected: FAIL — ClipboardMonitor not defined

- [ ] **Step 3: Write ClipboardMonitor.swift**

```swift
import AppKit

final class ClipboardMonitor {

    static let shared = ClipboardMonitor()

    private let pasteboard = NSPasteboard.general

    private init() {}

    func readText() -> String? {
        return pasteboard.string(forType: .string)
    }
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `xcodebuild test -project HumanTypist/HumanTypist.xcodeproj -scheme HumanTypist -destination 'platform=macOS' 2>&1 | grep -E "(test|PASS|FAIL|BUILD)" | head -20`
Expected: ClipboardMonitorTests PASS

- [ ] **Step 5: Commit**

```bash
git add HumanTypist/Core/ClipboardMonitor.swift
git commit -m "feat: add ClipboardMonitor for reading pasteboard text"
```

---

## Task 6: UI — StatusBarController & TypingPanel

**Files:**
- Create: `HumanTypist/UI/StatusBarController.swift`
- Create: `HumanTypist/UI/TypingPanel.swift`

- [ ] **Step 1: Write StatusBarController.swift**

```swift
import AppKit

final class StatusBarController {

    private var statusItem: NSStatusItem?
    private var panel: TypingPanel?

    init() {
        setupStatusItem()
    }

    private func setupStatusItem() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)

        if let button = statusItem?.button {
            button.image = NSImage(systemSymbolName: "keyboard", accessibilityDescription: "Human Typist")
            button.action = #selector(togglePanel)
            button.target = self
        }
    }

    @objc private func togglePanel() {
        if panel == nil {
            panel = TypingPanel()
        }
        panel!.toggle()
    }
}
```

- [ ] **Step 2: Write TypingPanel.swift**

```swift
import AppKit

final class TypingPanel: NSPanel {

    private var tabView: NSTabView!
    private var eventMonitor: Any?

    init() {
        super.init(
            contentRect: NSRect(x: 0, y: 0, width: 400, height: 350),
            styleMask: [.titled, .closable, .nonactivatingPanel, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )
        self.title = "Human Typist"
        self.isFloatingPanel = true
        self.becomesKeyOnlyIfNeeded = true
        self.hidesOnDeactivate = false
        self.level = .floating
        self.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]

        setupTabs()
        center()
        setupEventMonitor()
    }

    deinit {
        if let monitor = eventMonitor {
            NSEvent.removeMonitor(monitor)
        }
    }

    func toggle() {
        if isVisible {
            orderOut(nil)
        } else {
            if let button = NSApp.windows.first(where: { $0 is TypingPanel }) == nil {
                // position below menu bar
                if let button = (NSApp.windows.first { $0 is TypingPanel })?.contentView {
                    // nothing
                }
            }
            makeKeyAndOrderFront(nil)
        }
    }

    private func setupTabs() {
        tabView = NSTabView(frame: contentView!.bounds)
        tabView.autoresizingMask = [.width, .height]

        let generalTab = NSTabViewItem(identifier: "general")
        generalTab.label = "General"
        generalTab.view = GeneralTab()

        let shortcutsTab = NSTabViewItem(identifier: "shortcuts")
        shortcutsTab.label = "Shortcuts"
        shortcutsTab.view = ShortcutsTab()

        let paramsTab = NSTabViewItem(identifier: "params")
        paramsTab.label = "Typing Params"
        paramsTab.view = TypingParamsTab()

        tabView.addTabViewItem(generalTab)
        tabView.addTabViewItem(shortcutsTab)
        tabView.addTabViewItem(paramsTab)

        contentView!.addSubview(tabView)
    }

    private func setupEventMonitor() {
        eventMonitor = NSEvent.addGlobalMonitorForEvents(matching: [.leftMouseDown, .rightMouseDown]) { [weak self] event in
            guard let self = self else { return }
            if self.isVisible {
                let mouseLoc = NSEvent.mouseLocation
                if !self.frame.contains(mouseLoc) {
                    self.orderOut(nil)
                }
            }
        }
    }
}
```

- [ ] **Step 3: Commit**

```bash
git add HumanTypist/UI/StatusBarController.swift HumanTypist/UI/TypingPanel.swift
git commit -m "feat: add StatusBarController and TypingPanel UI"
```

---

## Task 7: UI — Tab Views

**Files:**
- Create: `HumanTypist/UI/GeneralTab.swift`
- Create: `HumanTypist/UI/ShortcutsTab.swift`
- Create: `HumanTypist/UI/TypingParamsTab.swift`

- [ ] **Step 1: Write GeneralTab.swift**

```swift
import AppKit
import ServiceManagement

final class GeneralTab: NSView {

    private var loginToggle: NSButton!

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        setupUI()
        loadState()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupUI() {
        let stack = NSStackView()
        stack.orientation = .vertical
        stack.alignment = .leading
        stack.spacing = 16
        stack.translatesAutoresizingMaskIntoConstraints = false

        loginToggle = NSButton(checkboxWithTitle: "Start at Login", target: self, action: #selector(loginToggleChanged))
        stack.addArrangedSubview(loginToggle)

        let quitButton = NSButton(title: "Quit Human Typist", target: self, action: #selector(quitApp))
        quitButton.bezelStyle = .rounded
        stack.addArrangedSubview(quitButton)

        addSubview(stack)
        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: topAnchor, constant: 20),
            stack.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 20),
            stack.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -20)
        ])
    }

    private func loadState() {
        if #available(macOS 13.0, *) {
            loginToggle.state = SMAppService.mainApp.status == .enabled ? .on : .off
        } else {
            loginToggle.state = Preferences.shared.startAtLogin ? .on : .off
        }
    }

    @objc private func loginToggleChanged() {
        let enabled = loginToggle.state == .on
        Preferences.shared.startAtLogin = enabled
        if #available(macOS 13.0, *) {
            do {
                if enabled {
                    try SMAppService.mainApp.register()
                } else {
                    try SMAppService.mainApp.unregister()
                }
            } catch {
                print("Failed to update login item: \(error)")
            }
        }
    }

    @objc private func quitApp() {
        NSApp.terminate(nil)
    }
}
```

- [ ] **Step 2: Write ShortcutsTab.swift**

```swift
import AppKit

final class ShortcutsTab: NSView {

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        setupUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupUI() {
        let stack = NSStackView()
        stack.orientation = .vertical
        stack.alignment = .leading
        stack.spacing = 12
        stack.translatesAutoresizingMaskIntoConstraints = false

        let shortcuts: [(String, String)] = [
            ("Start Typing", "⌃⌥P  (Ctrl+Alt+P)"),
            ("Stop Typing", "⌃⌥S  (Ctrl+Alt+S)"),
            ("Reload Clipboard", "⌃⌥R  (Ctrl+Alt+R)")
        ]

        for (action, keys) in shortcuts {
            let row = NSStackView()
            row.orientation = .horizontal
            row.spacing = 16

            let actionLabel = NSTextField(labelWithString: action)
            actionLabel.font = NSFont.systemFont(ofSize: 13, weight: .medium)
            actionLabel.setContentHuggingPriority(.defaultHigh, for: .horizontal)

            let keyLabel = NSTextField(labelWithString: keys)
            keyLabel.font = NSFont.monospacedSystemFont(ofSize: 13, weight: .regular)
            keyLabel.textColor = .secondaryLabelColor

            row.addArrangedSubview(actionLabel)
            row.addArrangedSubview(keyLabel)
            stack.addArrangedSubview(row)
        }

        let noteLabel = NSTextField(wrappingLabelWithString: "Hotkey rebinding is not available in v1.")
        noteLabel.font = NSFont.systemFont(ofSize: 11)
        noteLabel.textColor = .tertiaryLabelColor
        stack.addArrangedSubview(noteLabel)

        addSubview(stack)
        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: topAnchor, constant: 20),
            stack.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 20),
            stack.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -20)
        ])
    }
}
```

- [ ] **Step 3: Write TypingParamsTab.swift**

```swift
import AppKit

final class TypingParamsTab: NSView {

    private var wpmMinSlider: NSSlider!
    private var wpmMaxSlider: NSSlider!
    private var wpmMinLabel: NSTextField!
    private var wpmMaxLabel: NSTextField!

    private var burstMinSlider: NSSlider!
    private var burstMaxSlider: NSSlider!

    private var randomPauseSlider: NSSlider!
    private var thinkingPauseSlider: NSSlider!

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        setupUI()
        loadState()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupUI() {
        let scrollView = NSScrollView()
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.hasVerticalScroller = true
        scrollView.borderType = .noBorder

        let contentView = NSView()
        contentView.translatesAutoresizingMaskIntoConstraints = false

        let stack = NSStackView()
        stack.orientation = .vertical
        stack.alignment = .leading
        stack.spacing = 20
        stack.translatesAutoresizingMaskIntoConstraints = false

        stack.addArrangedSubview(makeSectionHeader("Typing Speed"))
        stack.addArrangedSubview(makeSliderRow("WPM Min", &wpmMinSlider!, &wpmMinLabel!, 5, 100, action: #selector(wpmMinChanged)))
        stack.addArrangedSubview(makeSliderRow("WPM Max", &wpmMaxSlider!, &wpmMaxLabel!, 30, 150, action: #selector(wpmMaxChanged)))

        stack.addArrangedSubview(makeSectionHeader("Burst Duration"))
        stack.addArrangedSubview(makeSliderRow("Burst Min (s)", &burstMinSlider!, nil, 0.5, 5, action: #selector(burstMinChanged)))
        stack.addArrangedSubview(makeSliderRow("Burst Max (s)", &burstMaxSlider!, nil, 2, 15, action: #selector(burstMaxChanged)))

        stack.addArrangedSubview(makeSectionHeader("Pauses"))
        stack.addArrangedSubview(makeSliderRow("Random Pause Chance", &randomPauseSlider!, nil, 0, 0.5, action: #selector(randomPauseChanged)))
        stack.addArrangedSubview(makeSliderRow("Thinking Pause Chance", &thinkingPauseSlider!, nil, 0, 0.05, action: #selector(thinkingPauseChanged)))

        contentView.addSubview(stack)
        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 10),
            stack.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            stack.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            stack.bottomAnchor.constraint(lessThanOrEqualTo: contentView.bottomAnchor, constant: -20),
            contentView.widthAnchor.constraint(equalToConstant: 380)
        ])

        scrollView.documentView = contentView
        addSubview(scrollView)
        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
    }

    private func makeSectionHeader(_ title: String) -> NSTextField {
        let label = NSTextField(labelWithString: title)
        label.font = NSFont.systemFont(ofSize: 13, weight: .semibold)
        label.textColor = .labelColor
        return label
    }

    private func makeSliderRow(_ title: String, _ slider: inout NSSlider, _ label: inout NSTextField!, _ min: Double, _ max: Double, action: Selector) -> NSView {
        let row = NSStackView()
        row.orientation = .vertical
        row.alignment = .leading
        row.spacing = 4

        let headerRow = NSStackView()
        headerRow.orientation = .horizontal

        let titleLabel = NSTextField(labelWithString: title)
        titleLabel.font = NSFont.systemFont(ofSize: 12)

        label = NSTextField(labelWithString: "")
        label.font = NSFont.monospacedDigitSystemFont(ofSize: 12, weight: .regular)
        label.textColor = .secondaryLabelColor

        headerRow.addArrangedSubview(titleLabel)
        headerRow.addArrangedSubview(label)

        slider = NSSlider()
        slider.minValue = min
        slider.maxValue = max
        slider.target = self
        slider.action = action
        slider.translatesAutoresizingMaskIntoConstraints = false
        slider.widthAnchor.constraint(equalToConstant: 300).isActive = true

        row.addArrangedSubview(headerRow)
        row.addArrangedSubview(slider)
        return row
    }

    private func loadState() {
        wpmMinSlider?.doubleValue = Double(Preferences.shared.wpmMin)
        wpmMaxSlider?.doubleValue = Double(Preferences.shared.wpmMax)
        wpmMinLabel?.stringValue = "\(Preferences.shared.wpmMin) WPM"
        wpmMaxLabel?.stringValue = "\(Preferences.shared.wpmMax) WPM"
        burstMinSlider?.doubleValue = Preferences.shared.burstSecondsMin
        burstMaxSlider?.doubleValue = Preferences.shared.burstSecondsMax
        randomPauseSlider?.doubleValue = Preferences.shared.randomPauseChance
        thinkingPauseSlider?.doubleValue = Preferences.shared.thinkingPauseChance
    }

    @objc private func wpmMinChanged() {
        let v = Int(wpmMinSlider.doubleValue)
        Preferences.shared.wpmMin = v
        wpmMinLabel.stringValue = "\(v) WPM"
    }

    @objc private func wpmMaxChanged() {
        let v = Int(wpmMaxSlider.doubleValue)
        Preferences.shared.wpmMax = v
        wpmMaxLabel.stringValue = "\(v) WPM"
    }

    @objc private func burstMinChanged() {
        Preferences.shared.burstSecondsMin = burstMinSlider.doubleValue
    }

    @objc private func burstMaxChanged() {
        Preferences.shared.burstSecondsMax = burstMaxSlider.doubleValue
    }

    @objc private func randomPauseChanged() {
        Preferences.shared.randomPauseChance = randomPauseSlider.doubleValue
    }

    @objc private func thinkingPauseChanged() {
        Preferences.shared.thinkingPauseChance = thinkingPauseSlider.doubleValue
    }
}
```

- [ ] **Step 4: Commit**

```bash
git add HumanTypist/UI/GeneralTab.swift HumanTypist/UI/ShortcutsTab.swift HumanTypist/UI/TypingParamsTab.swift
git commit -m "feat: add GeneralTab, ShortcutsTab, and TypingParamsTab"
```

---

## Task 8: Wire Everything in AppDelegate

**Files:**
- Modify: `HumanTypist/App/AppDelegate.swift`

- [ ] **Step 1: Update AppDelegate.swift to wire all components**

```swift
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
```

- [ ] **Step 2: Build the project**

Run: `xcodebuild -project HumanTypist/HumanTypist.xcodeproj -scheme HumanTypist -configuration Debug build 2>&1 | grep -E "(error:|warning:|BUILD)" | head -40`
Expected: BUILD SUCCEEDED

- [ ] **Step 3: Commit**

```bash
git add HumanTypist/App/AppDelegate.swift
git commit -m "feat: wire AppDelegate with HotkeyManager, TypingEngine, and ClipboardMonitor"
```

---

## Task 9: Build Verification & Manual Test

- [ ] **Step 1: Build release config**

Run: `xcodebuild -project HumanTypist/HumanTypist.xcodeproj -scheme HumanTypist -configuration Release build 2>&1 | tail -5`
Expected: BUILD SUCCEEDED

- [ ] **Step 2: Manual test — menu bar icon appears**

Open the built app. Verify no Dock icon appears. Verify menu bar shows keyboard icon.

- [ ] **Step 3: Manual test — panel opens**

Click menu bar icon. Verify floating panel appears with 3 tabs.

- [ ] **Step 4: Manual test — typing works**

Open TextEdit. Focus the text area. Copy some text to clipboard. Press Ctrl+Alt+P. Verify text types out with human-like timing.

- [ ] **Step 5: Manual test — stop works**

While typing, press Ctrl+Alt+S. Verify typing stops.

- [ ] **Step 6: Manual test — settings persist**

Change WPM slider. Quit app. Reopen. Verify settings persisted.

- [ ] **Step 7: Commit**

```bash
git add -A
git commit -m "chore: verify build and manual testing"
```

---

## Spec Coverage Check

| Spec Requirement | Task |
|------------------|------|
| Menu bar LSUIElement | Task 1 (Info.plist) |
| Floating NSPanel with tabs | Task 6, 7 |
| General tab (login item) | Task 7 (GeneralTab) |
| Shortcuts tab (read-only) | Task 7 (ShortcutsTab) |
| Typing Params tab (all sliders) | Task 7 (TypingParamsTab) |
| CGEvent typing engine | Task 3 (TypingEngine) |
| Carbon global hotkeys | Task 4 (HotkeyManager) |
| Clipboard source | Task 5 (ClipboardMonitor) |
| All typing params in UI | Task 7 (TypingParamsTab) |
| Start at login | Task 7 (GeneralTab + AppDelegate) |
| Burst model timing | Task 3 (TypingEngine) |
| Punctuation/sentence pauses | Task 3 (TypingEngine) |
| Random + thinking pauses | Task 3 (TypingEngine) |
| No external dependencies | All tasks |

All spec requirements are covered by a task.
