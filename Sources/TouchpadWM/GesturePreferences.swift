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

enum PickerActivation: String, CaseIterable, Codable, Equatable {
  case touch
  case swipeUp
  case swipeDown

  var label: String {
    switch self {
    case .touch:
      "Touch"
    case .swipeUp:
      "Swipe up"
    case .swipeDown:
      "Swipe down"
    }
  }
}

enum PickerFingerCount: Int, CaseIterable, Codable, Equatable {
  case three = 3
  case four = 4
  case five = 5

  var fingerCount: Int {
    rawValue
  }

  var label: String {
    "\(rawValue) fingers"
  }
}

@Observable
final class GesturePreferences {
  private enum Key {
    static let sensitivity = "gestureSensitivity"
    static let hapticStrength = "gestureHapticStrength"
    static let pickerActivation = "pickerActivation"
    static let pickerFingerCount = "pickerTrigger"
    static let activationSensitivity = "activationSensitivity"
  }

  private let defaults: UserDefaults
  init(defaults: UserDefaults = .standard) {
    self.defaults = defaults
    sensitivity = Self.sensitivity(from: defaults)
    hapticStrength = Self.hapticStrength(from: defaults)
    pickerActivation = Self.pickerActivation(from: defaults)
    pickerFingerCount = Self.pickerFingerCount(from: defaults)
    activationSensitivity = Self.activationSensitivity(from: defaults)
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

  var pickerActivation: PickerActivation {
    didSet {
      defaults.set(pickerActivation.rawValue, forKey: Key.pickerActivation)
    }
  }

  var pickerFingerCount: PickerFingerCount {
    didSet {
      defaults.set(pickerFingerCount.rawValue, forKey: Key.pickerFingerCount)
    }
  }

  var activationSensitivity: GestureSensitivity {
    didSet {
      defaults.set(activationSensitivity.rawValue, forKey: Key.activationSensitivity)
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

  private static func pickerActivation(from defaults: UserDefaults) -> PickerActivation {
    guard let rawValue = defaults.string(forKey: Key.pickerActivation),
      let value = PickerActivation(rawValue: rawValue)
    else {
      return .touch
    }
    return value
  }

  private static func pickerFingerCount(from defaults: UserDefaults) -> PickerFingerCount {
    guard let rawValue = defaults.object(forKey: Key.pickerFingerCount) as? Int,
      let value = PickerFingerCount(rawValue: rawValue)
    else {
      return .three
    }
    return value
  }

  private static func activationSensitivity(from defaults: UserDefaults) -> GestureSensitivity {
    guard let rawValue = defaults.object(forKey: Key.activationSensitivity) as? Int,
      let value = GestureSensitivity(rawValue: rawValue)
    else {
      return .medium
    }
    return value
  }
}
