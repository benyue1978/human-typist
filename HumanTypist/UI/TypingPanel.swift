import AppKit

final class TypingPanel: NSPanel {

    private var tabSegmentedControl: NSSegmentedControl!
    private var generalView: GeneralTab!
    private var shortcutsView: ShortcutsTab!
    private var paramsView: TypingParamsTab!

    private var eventMonitor: Any?

    init() {
        super.init(
            contentRect: NSRect(x: 0, y: 0, width: 400, height: 350),
            styleMask: [.titled, .closable, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        self.title = "Human Typist"
        self.titlebarAppearsTransparent = false
        self.titleVisibility = .visible
        self.isFloatingPanel = true
        self.becomesKeyOnlyIfNeeded = true
        self.hidesOnDeactivate = false
        self.level = .floating
        self.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]

        setupUI()
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

    private func setupUI() {
        let container = NSView(frame: contentView!.bounds)
        container.autoresizingMask = [.width, .height]

        tabSegmentedControl = NSSegmentedControl(labels: ["General", "Shortcuts", "Typing Params"], trackingMode: .selectOne, target: self, action: #selector(tabChanged))
        tabSegmentedControl.selectedSegment = 0
        tabSegmentedControl.translatesAutoresizingMaskIntoConstraints = false

        generalView = GeneralTab()
        shortcutsView = ShortcutsTab()
        paramsView = TypingParamsTab()

        [generalView, shortcutsView, paramsView].forEach { view in
            view.translatesAutoresizingMaskIntoConstraints = false
            view.isHidden = (view !== generalView)
            container.addSubview(view)
        }

        container.addSubview(tabSegmentedControl)

        NSLayoutConstraint.activate([
            tabSegmentedControl.topAnchor.constraint(equalTo: container.topAnchor, constant: 12),
            tabSegmentedControl.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 12),
            tabSegmentedControl.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -12),

            generalView.topAnchor.constraint(equalTo: tabSegmentedControl.bottomAnchor, constant: 12),
            generalView.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            generalView.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            generalView.bottomAnchor.constraint(equalTo: container.bottomAnchor),

            shortcutsView.topAnchor.constraint(equalTo: tabSegmentedControl.bottomAnchor, constant: 12),
            shortcutsView.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            shortcutsView.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            shortcutsView.bottomAnchor.constraint(equalTo: container.bottomAnchor),

            paramsView.topAnchor.constraint(equalTo: tabSegmentedControl.bottomAnchor, constant: 12),
            paramsView.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            paramsView.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            paramsView.bottomAnchor.constraint(equalTo: container.bottomAnchor),
        ])

        contentView!.addSubview(container)
    }

    @objc private func tabChanged() {
        let selected = tabSegmentedControl.selectedSegment
        generalView.isHidden = (selected != 0)
        shortcutsView.isHidden = (selected != 1)
        paramsView.isHidden = (selected != 2)
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
