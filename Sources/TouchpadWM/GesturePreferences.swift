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
      1.6
    case .low:
      1.35
    case .medium:
      1.1
    case .high:
      0.9
    case .highest:
      0.7
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
  static let pickerWidthRange = 360.0...800.0
  static let pickerWidthStep = 40.0
  static let pickerVisibleRowsRange = 3...10

  private static let defaultPickerWidth = 360.0
  private static let defaultPickerVisibleRows = 5

  private enum Key {
    static let sensitivity = "gestureSensitivity"
    static let hapticStrength = "gestureHapticStrength"
    static let pickerActivation = "pickerActivation"
    static let pickerFingerCount = "pickerTrigger"
    static let activationSensitivity = "activationSensitivity"
    static let pickerWidth = "pickerWidth"
    static let pickerVisibleRows = "pickerVisibleRows"
  }

  private let defaults: UserDefaults
  init(defaults: UserDefaults = .standard) {
    self.defaults = defaults
    sensitivity = Self.sensitivity(from: defaults)
    hapticStrength = Self.hapticStrength(from: defaults)
    pickerActivation = Self.pickerActivation(from: defaults)
    pickerFingerCount = Self.pickerFingerCount(from: defaults)
    activationSensitivity = Self.activationSensitivity(from: defaults)
    pickerWidth = Self.pickerWidth(from: defaults)
    pickerVisibleRows = Self.pickerVisibleRows(from: defaults)
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

  var pickerWidth: Double {
    didSet {
      let validatedValue = Self.validatedPickerWidth(pickerWidth)
      if pickerWidth != validatedValue {
        pickerWidth = validatedValue
      } else {
        defaults.set(pickerWidth, forKey: Key.pickerWidth)
      }
    }
  }

  var pickerVisibleRows: Int {
    didSet {
      let validatedValue = Self.validatedPickerVisibleRows(pickerVisibleRows)
      if pickerVisibleRows != validatedValue {
        pickerVisibleRows = validatedValue
      } else {
        defaults.set(pickerVisibleRows, forKey: Key.pickerVisibleRows)
      }
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

  private static func pickerWidth(from defaults: UserDefaults) -> Double {
    guard let value = defaults.object(forKey: Key.pickerWidth) as? Double else {
      return defaultPickerWidth
    }
    return validatedPickerWidth(value)
  }

  private static func pickerVisibleRows(from defaults: UserDefaults) -> Int {
    guard let value = defaults.object(forKey: Key.pickerVisibleRows) as? Int else {
      return defaultPickerVisibleRows
    }
    return validatedPickerVisibleRows(value)
  }

  private static func validatedPickerWidth(_ value: Double) -> Double {
    let stepCount = (value - pickerWidthRange.lowerBound) / pickerWidthStep
    guard pickerWidthRange.contains(value), stepCount == stepCount.rounded() else {
      return defaultPickerWidth
    }
    return value
  }

  private static func validatedPickerVisibleRows(_ value: Int) -> Int {
    pickerVisibleRowsRange.contains(value) ? value : defaultPickerVisibleRows
  }
}
