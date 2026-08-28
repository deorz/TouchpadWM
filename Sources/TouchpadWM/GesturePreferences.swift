import Foundation
import Observation

enum GestureSensitivity: Int, CaseIterable, Codable, Equatable {
  case lowest
  case low
  case medium
  case high
  case highest

  var movementMultiplier: Float {
    switch self {
    case .lowest:
      0.6
    case .low:
      0.8
    case .medium:
      1.0
    case .high:
      1.25
    case .highest:
      1.5
    }
  }

  var accessibilityLabel: String {
    switch self {
    case .lowest:
      "Lowest"
    case .low:
      "Low"
    case .medium:
      "Medium"
    case .high:
      "High"
    case .highest:
      "Highest"
    }
  }
}

enum HapticFeedbackStrength: String, CaseIterable, Codable, Equatable {
  case off
  case light
  case standard
  case strong

  var label: String {
    switch self {
    case .off:
      "Off"
    case .light:
      "Light"
    case .standard:
      "Standard"
    case .strong:
      "Strong"
    }
  }
}

enum PickerTrigger: Int, CaseIterable, Codable, Equatable {
  case threeFingers = 3
  case fourFingers = 4
  case fiveFingers = 5

  var fingerCount: Int {
    rawValue
  }

  var label: String {
    "Touch with \(rawValue) fingers"
  }
}

@Observable
final class GesturePreferences {
  private enum Key {
    static let sensitivity = "gestureSensitivity"
    static let hapticStrength = "gestureHapticStrength"
    static let pickerTrigger = "pickerTrigger"
  }

  private let defaults: UserDefaults
  init(defaults: UserDefaults = .standard) {
    self.defaults = defaults
    sensitivity = Self.sensitivity(from: defaults)
    hapticStrength = Self.hapticStrength(from: defaults)
    pickerTrigger = Self.pickerTrigger(from: defaults)
  }

  var sensitivity: GestureSensitivity {
    didSet {
      defaults.set(sensitivity.rawValue, forKey: Key.sensitivity)
    }
  }

  var hapticStrength: HapticFeedbackStrength {
    didSet {
      defaults.set(hapticStrength.rawValue, forKey: Key.hapticStrength)
    }
  }

  var pickerTrigger: PickerTrigger {
    didSet {
      defaults.set(pickerTrigger.rawValue, forKey: Key.pickerTrigger)
    }
  }

  private static func sensitivity(from defaults: UserDefaults) -> GestureSensitivity {
    guard let rawValue = defaults.object(forKey: Key.sensitivity) as? Int,
      let value = GestureSensitivity(rawValue: rawValue)
    else {
      return .medium
    }
    return value
  }

  private static func hapticStrength(from defaults: UserDefaults) -> HapticFeedbackStrength {
    guard let rawValue = defaults.string(forKey: Key.hapticStrength),
      let value = HapticFeedbackStrength(rawValue: rawValue)
    else {
      return .standard
    }
    return value
  }

  private static func pickerTrigger(from defaults: UserDefaults) -> PickerTrigger {
    guard let rawValue = defaults.object(forKey: Key.pickerTrigger) as? Int,
      let value = PickerTrigger(rawValue: rawValue)
    else {
      return .threeFingers
    }
    return value
  }
}
