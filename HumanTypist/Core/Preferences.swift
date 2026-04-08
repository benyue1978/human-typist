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
