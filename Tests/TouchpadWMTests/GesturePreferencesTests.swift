import Observation
import XCTest

@testable import TouchpadWM

final class GesturePreferencesTests: XCTestCase {
  func testMissingPreferencesUseTheCurrentGestureDefaults() {
    let preferences = GesturePreferences(defaults: makeDefaults())

    XCTAssertEqual(preferences.sensitivity, .medium)
    XCTAssertEqual(preferences.hapticStrength, .standard)
    XCTAssertEqual(preferences.pickerTrigger, .threeFingers)
  }

  func testPreferencesPersistAcrossStoreInstances() {
    let defaults = makeDefaults()
    let first = GesturePreferences(defaults: defaults)
    first.sensitivity = .lowest
    first.hapticStrength = .light
    first.pickerTrigger = .fiveFingers

    let second = GesturePreferences(defaults: defaults)

    XCTAssertEqual(second.sensitivity, .lowest)
    XCTAssertEqual(second.hapticStrength, .light)
    XCTAssertEqual(second.pickerTrigger, .fiveFingers)
  }

  func testSensitivityPointsMapToIncreasingMovementMultipliers() {
    XCTAssertEqual(
      GestureSensitivity.allCases.map(\.movementMultiplier),
      [0.6, 0.8, 1.0, 1.25, 1.5])
  }

  func testGestureOptionsExposeAccessibleLabelsWithoutNumericSensitivityValues() {
    XCTAssertEqual(
      GestureSensitivity.allCases.map(\.accessibilityLabel),
      ["Lowest", "Low", "Medium", "High", "Highest"])
    XCTAssertEqual(
      HapticFeedbackStrength.allCases.map(\.label),
      ["Off", "Light", "Standard", "Strong"])
    XCTAssertEqual(PickerTrigger.allCases.map(\.fingerCount), [3, 4, 5])
    XCTAssertEqual(
      PickerTrigger.allCases.map(\.label),
      ["Touch with 3 fingers", "Touch with 4 fingers", "Touch with 5 fingers"])
  }

  func testInvalidStoredValuesFallBackToSafeDefaults() {
    let defaults = makeDefaults()
    defaults.set(99, forKey: "gestureSensitivity")
    defaults.set("invalid", forKey: "gestureHapticStrength")
    defaults.set(2, forKey: "pickerTrigger")

    let preferences = GesturePreferences(defaults: defaults)

    XCTAssertEqual(preferences.sensitivity, .medium)
    XCTAssertEqual(preferences.hapticStrength, .standard)
    XCTAssertEqual(preferences.pickerTrigger, .threeFingers)
  }

  func testChangingPreferenceProducesAnObservationUpdate() {
    let preferences = GesturePreferences(defaults: makeDefaults())
    let counter = ObservationCounter()

    withObservationTracking(
      {
        _ = preferences.sensitivity
      },
      onChange: {
        counter.increment()
      })

    preferences.sensitivity = .high

    XCTAssertEqual(counter.count, 1)
  }

  private func makeDefaults() -> UserDefaults {
    let name = "GesturePreferencesTests.\(UUID().uuidString)"
    let defaults = UserDefaults(suiteName: name)!
    addTeardownBlock {
      UserDefaults(suiteName: name)?.removePersistentDomain(forName: name)
    }
    return defaults
  }
}

private final class ObservationCounter: @unchecked Sendable {
  private(set) var count = 0

  func increment() {
    count += 1
  }
}
