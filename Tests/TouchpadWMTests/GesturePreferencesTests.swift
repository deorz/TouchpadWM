import Observation
import XCTest

@testable import TouchpadWM

final class GesturePreferencesTests: XCTestCase {
  func testMissingPreferencesUseTheCurrentGestureDefaults() {
    let preferences = GesturePreferences(defaults: makeDefaults())

    XCTAssertEqual(preferences.sensitivity, .medium)
    XCTAssertEqual(preferences.hapticStrength, .standard)
    XCTAssertEqual(preferences.pickerActivation, .touch)
    XCTAssertEqual(preferences.pickerFingerCount, .three)
    XCTAssertEqual(preferences.activationSensitivity, .medium)
    XCTAssertEqual(preferences.pickerWidth, 360)
    XCTAssertEqual(preferences.pickerVisibleRows, 5)
  }

  func testPreferencesPersistAcrossStoreInstances() {
    let defaults = makeDefaults()
    let first = GesturePreferences(defaults: defaults)
    first.sensitivity = .lowest
    first.hapticStrength = .light
    first.pickerActivation = .swipeDown
    first.pickerFingerCount = .five
    first.activationSensitivity = .highest
    first.pickerWidth = 800
    first.pickerVisibleRows = 10

    let second = GesturePreferences(defaults: defaults)

    XCTAssertEqual(second.sensitivity, .lowest)
    XCTAssertEqual(second.hapticStrength, .light)
    XCTAssertEqual(second.pickerActivation, .swipeDown)
    XCTAssertEqual(second.pickerFingerCount, .five)
    XCTAssertEqual(second.activationSensitivity, .highest)
    XCTAssertEqual(second.pickerWidth, 800)
    XCTAssertEqual(second.pickerVisibleRows, 10)
  }

  func testSensitivityPointsMapToDecreasingMovementRequirements() {
    XCTAssertEqual(
      GestureSensitivity.allCases.map(\.movementMultiplier),
      [1.6, 1.35, 1.1, 0.9, 0.7])
  }

  func testGestureOptionsExposeAccessibleLabelsWithoutNumericSensitivityValues() {
    XCTAssertEqual(
      GestureSensitivity.allCases.map(\.accessibilityLabel),
      ["Lowest", "Low", "Medium", "High", "Highest"])
    XCTAssertEqual(
      HapticFeedbackStrength.allCases.map(\.label),
      ["Off", "Light", "Standard", "Strong"])
    XCTAssertEqual(PickerActivation.allCases.map(\.label), ["Touch", "Swipe up", "Swipe down"])
    XCTAssertEqual(
      PickerFingerCount.allCases.map(\.label),
      ["3 fingers", "4 fingers", "5 fingers"])
  }

  func testSensitivitySliderEndpointsDescribeRequiredMovement() {
    XCTAssertEqual(GestureSensitivitySliderLabels.minimumValue, "Less")
    XCTAssertEqual(GestureSensitivitySliderLabels.maximumValue, "More")
  }

  func testInvalidStoredValuesFallBackToSafeDefaults() {
    let defaults = makeDefaults()
    defaults.set(99, forKey: "gestureSensitivity")
    defaults.set("invalid", forKey: "gestureHapticStrength")
    defaults.set("invalid", forKey: "pickerActivation")
    defaults.set(2, forKey: "pickerTrigger")
    defaults.set(99, forKey: "activationSensitivity")
    defaults.set(361, forKey: "pickerWidth")
    defaults.set(20, forKey: "pickerVisibleRows")

    let preferences = GesturePreferences(defaults: defaults)

    XCTAssertEqual(preferences.sensitivity, .medium)
    XCTAssertEqual(preferences.hapticStrength, .standard)
    XCTAssertEqual(preferences.pickerActivation, .touch)
    XCTAssertEqual(preferences.pickerFingerCount, .three)
    XCTAssertEqual(preferences.activationSensitivity, .medium)
    XCTAssertEqual(preferences.pickerWidth, 360)
    XCTAssertEqual(preferences.pickerVisibleRows, 5)
  }

  func testUnsupportedPickerLayoutAssignmentsFallBackToSafeDefaults() {
    let preferences = GesturePreferences(defaults: makeDefaults())

    preferences.pickerWidth = 840
    preferences.pickerVisibleRows = 11

    XCTAssertEqual(preferences.pickerWidth, 360)
    XCTAssertEqual(preferences.pickerVisibleRows, 5)
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
