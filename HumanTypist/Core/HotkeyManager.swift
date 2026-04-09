import Foundation
import CoreGraphics
import AppKit

final class HotkeyManager {

    static let shared = HotkeyManager()

    private var eventTap: CFMachPort?
    private var runLoopSource: CFRunLoopSource?
    private(set) var isRegistered = false

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

        NSLog("[HotkeyManager] register() called")

        // First check/request Accessibility permission
        let options = [kAXTrustedCheckOptionPrompt.takeRetainedValue() as String: true] as CFDictionary
        let trusted = AXIsProcessTrustedWithOptions(options)
        NSLog("[HotkeyManager] AXIsProcessTrustedWithOptions: %@", "\(trusted)")

        // Note: permission must be granted BEFORE this app launch, not just during this session
        if !trusted {
            NSLog("[HotkeyManager] Accessibility permission NOT granted - CGEvent tap will likely fail")
        }

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
            NSLog("[HotkeyManager] CGEvent.tapCreate FAILED - Accessibility permission issue")
            return
        }

        NSLog("[HotkeyManager] Event tap created successfully!")
        eventTap = tap
        runLoopSource = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, tap, 0)
        CFRunLoopAddSource(CFRunLoopGetMain(), runLoopSource, .commonModes)
        CGEvent.tapEnable(tap: tap, enable: true)
        isRegistered = true
    }

    private func handleEvent(proxy: CGEventTapProxy, type: CGEventType, event: CGEvent) {
        guard type == .keyDown else { return }

        let keyCode = event.getIntegerValueField(.keyboardEventKeycode)
        let flags = event.flags

        let hasControl = flags.contains(.maskControl)
        let hasOption = flags.contains(.maskAlternate)

        guard hasControl && hasOption else { return }

        NSLog("[HotkeyManager] Key pressed: keycode=%lld ctrl=%@ opt=%@", keyCode, "\(hasControl)", "\(hasOption)")

        switch keyCode {
        case 0x23: // P = 35 decimal
            NSLog("[HotkeyManager] matched case 0x23 (P), calling onStart")
            self.onStart?()
        case 0x1F: // S = 31 decimal
            NSLog("[HotkeyManager] matched case 0x1F (S), calling onStop")
            self.onStop?()
        case 0x0F: // R = 15 decimal
            NSLog("[HotkeyManager] matched case 0x0F (R), calling onReload")
            self.onReload?()
        default:
            NSLog("[HotkeyManager] no match for keycode=%lld, falling through", keyCode)
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
