import Foundation
import CoreGraphics
import AppKit

final class HotkeyManager {

    static let shared = HotkeyManager()

    private var eventTap: CFMachPort?
    private var runLoopSource: CFRunLoopSource?
    private var isRegistered = false

    var onStart: (() -> Void)?
    var onStop: (() -> Void)?
    var onReload: (() -> Void)?

    private init() {}

    func register(onStart: @escaping () -> Void,
                   onStop: @escaping () -> Void,
                   onReload: @escaping () -> Void) {
        self.onStart = onStart
        self.onStop = onStop
        self.onReload = onReload

        // Ctrl+Alt+P = keycode 0x35, modifiers: control + option
        let startKey = KeyCombo(keyCode: 0x35, modifiers: 0x1100) // controlKey | optionKey
        // Ctrl+Alt+S = keycode 0x01
        let stopKey = KeyCombo(keyCode: 0x01, modifiers: 0x1100)
        // Ctrl+Alt+R = keycode 0x0F
        let reloadKey = KeyCombo(keyCode: 0x0F, modifiers: 0x1100)

        let eventMask = (1 << CGEventType.keyDown.rawValue)

        let refcon = UnsafeMutableRawPointer(Unmanaged.passUnretained(self).toOpaque())

        guard let tap = CGEvent.tapCreate(
            tap: .cgSessionEventTap,
            place: .headInsertEventTap,
            options: .defaultTap,
            eventsOfInterest: CGEventMask(eventMask),
            callback: { (proxy, type, event, refcon) -> Unmanaged<CGEvent>? in
                guard let refcon = refcon else { return Unmanaged.passRetained(event) }
                let manager = Unmanaged<HotkeyManager>.fromOpaque(refcon).takeUnretainedValue()
                manager.handleEvent(proxy: proxy, type: type, event: event)
                return Unmanaged.passRetained(event)
            },
            userInfo: refcon
        ) else {
            print("[HotkeyManager] CGEvent.tapCreate FAILED - need Accessibility permission")
            return
        }

        eventTap = tap
        runLoopSource = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, tap, 0)
        CFRunLoopAddSource(CFRunLoopGetMain(), runLoopSource, .commonModes)
        CGEvent.tapEnable(tap: tap, enable: true)

        print("[HotkeyManager] Event tap enabled successfully")
        isRegistered = true
    }

    private func handleEvent(proxy: CGEventTapProxy, type: CGEventType, event: CGEvent) {
        guard type == .keyDown else { return }

        let keyCode = event.getIntegerValueField(.keyboardEventKeycode)
        let flags = event.flags

        // Check for Ctrl+Option modifiers
        let hasControl = flags.contains(.maskControl)
        let hasOption = flags.contains(.maskAlternate)

        guard hasControl && hasOption else { return }

        print("[HotkeyManager] Key pressed: keycode=\(keyCode) ctrl=\(hasControl) opt=\(hasOption)")

        switch keyCode {
        case 0x35: // P
            DispatchQueue.main.async { self.onStart?() }
        case 0x01: // S
            DispatchQueue.main.async { self.onStop?() }
        case 0x0F: // R
            DispatchQueue.main.async { self.onReload?() }
        default:
            break
        }
    }

    func unregister() {
        if let tap = eventTap {
            CGEvent.tapEnable(tap: tap, enable: false)
            CFRunLoopRemoveSource(CFRunLoopGetMain(), runLoopSource, .commonModes)
            eventTap = nil
            runLoopSource = nil
        }
        isRegistered = false
    }
}

struct KeyCombo {
    let keyCode: Int64
    let modifiers: Int64
}
