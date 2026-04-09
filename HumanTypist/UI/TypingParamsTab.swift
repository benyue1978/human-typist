import AppKit

final class TypingParamsTab: NSView {

    private var wpmMinSlider: NSSlider!
    private var wpmMaxSlider: NSSlider!
    private var wpmMinLabel: NSTextField!
    private var wpmMaxLabel: NSTextField!

    private var burstMinSlider: NSSlider!
    private var burstMaxSlider: NSSlider!
    private var burstMinLabel: NSTextField!
    private var burstMaxLabel: NSTextField!

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

        // --- Typing Speed ---
        stack.addArrangedSubview(makeSectionHeader("Typing Speed", helpText: "Target WPM range. Actual speed varies per character for realism."))

        let (wpmMinRow, wpmMinS, wpmMinL) = makeSliderRow(
            label: "WPM Min",
            helpText: "Lower bound of typing speed (chars/min = WPM × 5 ÷ 60)",
            min: 20, max: 200, action: #selector(wpmMinChanged)
        )
        wpmMinSlider = wpmMinS
        wpmMinLabel = wpmMinL
        stack.addArrangedSubview(wpmMinRow)

        let (wpmMaxRow, wpmMaxS, wpmMaxL) = makeSliderRow(
            label: "WPM Max",
            helpText: "Upper bound. Random bursts pick a speed within this range.",
            min: 50, max: 500, action: #selector(wpmMaxChanged)
        )
        wpmMaxSlider = wpmMaxS
        wpmMaxLabel = wpmMaxL
        stack.addArrangedSubview(wpmMaxRow)

        // --- Burst Duration ---
        stack.addArrangedSubview(makeSectionHeader("Burst Duration", helpText: "How long each typing burst runs before a short pause."))

        let (burstMinRow, burstMinS, burstMinL) = makeSliderRow(
            label: "Burst Min (s)",
            helpText: "Minimum seconds per burst (0.5 = ~1 sentence at fast WPM)",
            min: 0.5, max: 5, action: #selector(burstMinChanged)
        )
        burstMinSlider = burstMinS
        burstMinLabel = burstMinL
        stack.addArrangedSubview(burstMinRow)

        let (burstMaxRow, burstMaxS, burstMaxL) = makeSliderRow(
            label: "Burst Max (s)",
            helpText: "Maximum seconds per burst before a micro-pause",
            min: 2, max: 15, action: #selector(burstMaxChanged)
        )
        burstMaxSlider = burstMaxS
        burstMaxLabel = burstMaxL
        stack.addArrangedSubview(burstMaxRow)

        // --- Pauses ---
        stack.addArrangedSubview(makeSectionHeader("Pauses", helpText: "Randomized hesitation that makes typing feel human."))

        let (randomPauseRow, randomPauseS, _) = makeSliderRow(
            label: "Random Pause Chance",
            helpText: "Probability of a tiny 50–80ms pause after any character (0 = never, 0.5 = 50%)",
            min: 0, max: 0.5, action: #selector(randomPauseChanged)
        )
        randomPauseSlider = randomPauseS
        stack.addArrangedSubview(randomPauseRow)

        let (thinkingPauseRow, thinkingPauseS, _) = makeSliderRow(
            label: "Thinking Pause Chance",
            helpText: "Probability of a long 4–8 second pause (like pausing to think). Keep small.",
            min: 0, max: 0.05, action: #selector(thinkingPauseChanged)
        )
        thinkingPauseSlider = thinkingPauseS
        stack.addArrangedSubview(thinkingPauseRow)

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

    private func makeSectionHeader(_ title: String, helpText: String) -> NSView {
        let container = NSStackView()
        container.orientation = .vertical
        container.alignment = .leading
        container.spacing = 2

        let titleLabel = NSTextField(labelWithString: title)
        titleLabel.font = NSFont.systemFont(ofSize: 13, weight: .semibold)
        titleLabel.textColor = .labelColor

        let helpLabel = NSTextField(labelWithString: helpText)
        helpLabel.font = NSFont.systemFont(ofSize: 10)
        helpLabel.textColor = .secondaryLabelColor
        helpLabel.lineBreakMode = .byWordWrapping
        helpLabel.preferredMaxLayoutWidth = 330

        container.addArrangedSubview(titleLabel)
        container.addArrangedSubview(helpLabel)
        return container
    }

    private func makeSliderRow(label: String, helpText: String, min: Double, max: Double, action: Selector) -> (NSView, NSSlider, NSTextField) {
        let row = NSStackView()
        row.orientation = .vertical
        row.alignment = .leading
        row.spacing = 4

        let headerRow = NSStackView()
        headerRow.orientation = .horizontal

        let titleLabel = NSTextField(labelWithString: label)
        titleLabel.font = NSFont.systemFont(ofSize: 12)

        let label2 = NSTextField(labelWithString: "")
        label2.font = NSFont.monospacedDigitSystemFont(ofSize: 12, weight: .regular)
        label2.textColor = .secondaryLabelColor

        headerRow.addArrangedSubview(titleLabel)
        headerRow.addArrangedSubview(label2)

        let helpLabel = NSTextField(labelWithString: helpText)
        helpLabel.font = NSFont.systemFont(ofSize: 9)
        helpLabel.textColor = .tertiaryLabelColor
        helpLabel.lineBreakMode = .byWordWrapping
        helpLabel.preferredMaxLayoutWidth = 330

        let slider = NSSlider()
        slider.minValue = min
        slider.maxValue = max
        slider.target = self
        slider.action = action
        slider.translatesAutoresizingMaskIntoConstraints = false
        slider.widthAnchor.constraint(equalToConstant: 300).isActive = true

        row.addArrangedSubview(headerRow)
        row.addArrangedSubview(helpLabel)
        row.addArrangedSubview(slider)

        return (row, slider, label2)
    }

    private func loadState() {
        wpmMinSlider?.doubleValue = Double(Preferences.shared.wpmMin)
        wpmMaxSlider?.doubleValue = Double(Preferences.shared.wpmMax)
        wpmMinLabel?.stringValue = "\(Preferences.shared.wpmMin) WPM"
        wpmMaxLabel?.stringValue = "\(Preferences.shared.wpmMax) WPM"
        burstMinSlider?.doubleValue = Preferences.shared.burstSecondsMin
        burstMaxSlider?.doubleValue = Preferences.shared.burstSecondsMax
        burstMinLabel?.stringValue = String(format: "%.1fs", Preferences.shared.burstSecondsMin)
        burstMaxLabel?.stringValue = String(format: "%.1fs", Preferences.shared.burstSecondsMax)
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
        burstMinLabel.stringValue = String(format: "%.1fs", Preferences.shared.burstSecondsMin)
    }

    @objc private func burstMaxChanged() {
        Preferences.shared.burstSecondsMax = burstMaxSlider.doubleValue
        burstMaxLabel.stringValue = String(format: "%.1fs", Preferences.shared.burstSecondsMax)
    }

    @objc private func randomPauseChanged() {
        Preferences.shared.randomPauseChance = randomPauseSlider.doubleValue
    }

    @objc private func thinkingPauseChanged() {
        Preferences.shared.thinkingPauseChance = thinkingPauseSlider.doubleValue
    }
}
