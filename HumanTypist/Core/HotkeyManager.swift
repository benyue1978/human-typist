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

    // Ctrl+Alt+P = P keycode 0x35 (35), modifiers control+option
    // Ctrl+Alt+S = S keycode 0x01 (1), modifiers control+option
    // Ctrl+Alt+R = R keycode 0x0F (15), modifiers control+option
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