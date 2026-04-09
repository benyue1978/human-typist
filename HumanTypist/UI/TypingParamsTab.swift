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

        let (wpmMinRow, wpmMinS, wpmMinL) = makeSliderRow("WPM Min", 5, 100, action: #selector(wpmMinChanged))
        wpmMinSlider = wpmMinS
        wpmMinLabel = wpmMinL
        stack.addArrangedSubview(wpmMinRow)

        let (wpmMaxRow, wpmMaxS, wpmMaxL) = makeSliderRow("WPM Max", 30, 150, action: #selector(wpmMaxChanged))
        wpmMaxSlider = wpmMaxS
        wpmMaxLabel = wpmMaxL
        stack.addArrangedSubview(wpmMaxRow)

        stack.addArrangedSubview(makeSectionHeader("Burst Duration"))

        let (burstMinRow, burstMinS, _) = makeSliderRow("Burst Min (s)", 0.5, 5, action: #selector(burstMinChanged))
        burstMinSlider = burstMinS
        stack.addArrangedSubview(burstMinRow)

        let (burstMaxRow, burstMaxS, _) = makeSliderRow("Burst Max (s)", 2, 15, action: #selector(burstMaxChanged))
        burstMaxSlider = burstMaxS
        stack.addArrangedSubview(burstMaxRow)

        stack.addArrangedSubview(makeSectionHeader("Pauses"))

        let (randomPauseRow, randomPauseS, _) = makeSliderRow("Random Pause Chance", 0, 0.5, action: #selector(randomPauseChanged))
        randomPauseSlider = randomPauseS
        stack.addArrangedSubview(randomPauseRow)

        let (thinkingPauseRow, thinkingPauseS, _) = makeSliderRow("Thinking Pause Chance", 0, 0.05, action: #selector(thinkingPauseChanged))
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

    private func makeSectionHeader(_ title: String) -> NSTextField {
        let label = NSTextField(labelWithString: title)
        label.font = NSFont.systemFont(ofSize: 13, weight: .semibold)
        label.textColor = .labelColor
        return label
    }

    private func makeSliderRow(_ title: String, _ min: Double, _ max: Double, action: Selector) -> (NSView, NSSlider, NSTextField) {
        let row = NSStackView()
        row.orientation = .vertical
        row.alignment = .leading
        row.spacing = 4

        let headerRow = NSStackView()
        headerRow.orientation = .horizontal

        let titleLabel = NSTextField(labelWithString: title)
        titleLabel.font = NSFont.systemFont(ofSize: 12)

        let label = NSTextField(labelWithString: "")
        label.font = NSFont.monospacedDigitSystemFont(ofSize: 12, weight: .regular)
        label.textColor = .secondaryLabelColor

        headerRow.addArrangedSubview(titleLabel)
        headerRow.addArrangedSubview(label)

        let slider = NSSlider()
        slider.minValue = min
        slider.maxValue = max
        slider.target = self
        slider.action = action
        slider.translatesAutoresizingMaskIntoConstraints = false
        slider.widthAnchor.constraint(equalToConstant: 300).isActive = true

        row.addArrangedSubview(headerRow)
        row.addArrangedSubview(slider)

        return (row, slider, label)
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
