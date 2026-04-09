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

    private init() {}

    @discardableResult
    func register(onStart: @escaping () -> Void,
                   onStop: @escaping () -> Void) -> Bool {
        self.onStart = onStart
        self.onStop = onStop

        // First check/request Accessibility permission
        let options = [kAXTrustedCheckOptionPrompt.takeRetainedValue() as String: true] as CFDictionary
        let trusted = AXIsProcessTrustedWithOptions(options)

        if !trusted {
            return false
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
            return false
        }

        eventTap = tap
        runLoopSource = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, tap, 0)
        CFRunLoopAddSource(CFRunLoopGetMain(), runLoopSource, .commonModes)
        CGEvent.tapEnable(tap: tap, enable: true)
        isRegistered = true
        return true
    }

    private func handleEvent(proxy: CGEventTapProxy, type: CGEventType, event: CGEvent) {
        guard type == .keyDown else { return }

        let keyCode = event.getIntegerValueField(.keyboardEventKeycode)
        let flags = event.flags

        let hasControl = flags.contains(.maskControl)
        let hasOption = flags.contains(.maskAlternate)

        guard hasControl && hasOption else { return }

        switch keyCode {
        case 0x23: // P = 35 decimal
            self.onStart?()
        case 0x1F, 0x01: // S = 31 or 1 (different keyboard layouts report different keycodes)
            self.onStop?()
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
