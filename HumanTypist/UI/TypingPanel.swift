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
