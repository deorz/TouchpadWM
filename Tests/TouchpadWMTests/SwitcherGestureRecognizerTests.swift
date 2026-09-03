import TouchpadWMSpike
import XCTest

@testable import TouchpadWM

final class SwitcherGestureRecognizerTests: XCTestCase {
  func testDefaultFingerContactImmediatelyOpensTheSwitcher() {
    var recognizer = SwitcherGestureRecognizer()

    XCTAssertEqual(recognizer.consume(frame(y: 0.5)), [.openSwitcher])
  }

  func testConfiguredFingerCountsOpenTheSwitcher() {
    for (trigger, count) in [
      (PickerFingerCount.three, 3),
      (PickerFingerCount.four, 4),
      (PickerFingerCount.five, 5),
    ] {
      var recognizer = SwitcherGestureRecognizer(fingerCount: trigger)

      XCTAssertEqual(
        recognizer.consume(frame(count: count, y: 0.5)),
        [.openSwitcher],
        "Expected \(count)-finger trigger to open the switcher")
    }
  }

  func testConfiguredFingerCountIgnoresOtherContactCounts() {
    var recognizer = SwitcherGestureRecognizer(fingerCount: .four)

    XCTAssertEqual(recognizer.consume(frame(count: 3, y: 0.5)), [])
    XCTAssertEqual(recognizer.consume(frame(count: 5, y: 0.5)), [])
    XCTAssertEqual(recognizer.consume(frame(count: 4, y: 0.5)), [.openSwitcher])
  }

  func testLowerSensitivityRequiresMoreMovementForOneSelectionChange() {
    var recognizer = SwitcherGestureRecognizer(sensitivity: .lowest)
    _ = recognizer.consume(frame(y: 0.5))

    XCTAssertEqual(
      recognizer.consume(frame(y: 0.5 + SwitcherGestureRecognizer.rowDistance)), [])
  }

  func testHigherSensitivityChangesSelectionWithTheSameMovement() {
    var recognizer = SwitcherGestureRecognizer(sensitivity: .highest)
    _ = recognizer.consume(frame(y: 0.5))

    XCTAssertEqual(
      recognizer.consume(frame(y: 0.5 + SwitcherGestureRecognizer.rowDistance)),
      [.moveSwitcherSelection(.previous)])
  }

  func testUpdatingConfigurationAppliesToTheNextGesture() {
    var recognizer = SwitcherGestureRecognizer()
    recognizer.update(
      activation: .touch,
      fingerCount: .five,
      activationSensitivity: .medium,
      sensitivity: .highest)

    XCTAssertEqual(recognizer.consume(frame(count: 5, y: 0.5)), [.openSwitcher])
  }

  func testKeepingTheSameConfigurationDoesNotResetAnActiveGesture() {
    var recognizer = SwitcherGestureRecognizer()
    _ = recognizer.consume(frame(y: 0.5))
    recognizer.update(
      activation: .touch,
      fingerCount: .three,
      activationSensitivity: .medium,
      sensitivity: .medium)

    XCTAssertEqual(
      recognizer.consume(frame(y: 0.5 + SwitcherGestureRecognizer.rowDistance)),
      [.moveSwitcherSelection(.previous)])
  }

  func testSmallUpwardDeltasAccumulateUntilTheyCrossOneRow() {
    var recognizer = SwitcherGestureRecognizer()
    _ = recognizer.consume(frame(y: 0.5))

    XCTAssertEqual(recognizer.consume(frame(y: 0.53)), [])
    XCTAssertEqual(recognizer.consume(frame(y: 0.56)), [])
    XCTAssertEqual(recognizer.consume(frame(y: 0.59)), [.moveSwitcherSelection(.previous)])
  }

  func testFractionalDistanceRemainsForTheNextFrame() {
    var recognizer = SwitcherGestureRecognizer()
    _ = recognizer.consume(frame(y: 0.5))

    XCTAssertEqual(
      recognizer.consume(frame(y: 0.5 + 1.5 * SwitcherGestureRecognizer.rowDistance)),
      [.moveSwitcherSelection(.previous)])
    XCTAssertEqual(
      recognizer.consume(frame(y: 0.5 + 2 * SwitcherGestureRecognizer.rowDistance)),
      [.moveSwitcherSelection(.previous)])
  }

  func testCrossingTwoRowsInOneFrameEmitsTwoMoveCommands() {
    var recognizer = SwitcherGestureRecognizer()
    _ = recognizer.consume(frame(y: 0.5))

    XCTAssertEqual(
      recognizer.consume(frame(y: 0.5 + 2 * SwitcherGestureRecognizer.rowDistance)),
      [.moveSwitcherSelection(.previous), .moveSwitcherSelection(.previous)])
  }

  func testDownwardMovementMovesToTheNextRow() {
    var recognizer = SwitcherGestureRecognizer()
    _ = recognizer.consume(frame(y: 0.5))

    XCTAssertEqual(
      recognizer.consume(frame(y: 0.5 - SwitcherGestureRecognizer.rowDistance)),
      [.moveSwitcherSelection(.next)])
  }

  func testFastMovementIsLimitedToTwoSelectionChangesPerFrame() {
    var recognizer = SwitcherGestureRecognizer()
    _ = recognizer.consume(frame(y: 0.5))

    XCTAssertEqual(
      recognizer.consume(frame(y: 0.5 + 5 * SwitcherGestureRecognizer.rowDistance)),
      [.moveSwitcherSelection(.previous), .moveSwitcherSelection(.previous)])
    XCTAssertEqual(
      recognizer.consume(frame(y: 0.5 + 5 * SwitcherGestureRecognizer.rowDistance)),
      [.moveSwitcherSelection(.previous), .moveSwitcherSelection(.previous)])
  }

  func testDirectionReversalRetainsOnlyTheNetResidualDistance() {
    var recognizer = SwitcherGestureRecognizer()
    _ = recognizer.consume(frame(y: 0.5))

    XCTAssertEqual(recognizer.consume(frame(y: 0.56)), [])
    XCTAssertEqual(recognizer.consume(frame(y: 0.52)), [])
    XCTAssertEqual(recognizer.consume(frame(y: 0.58)), [.moveSwitcherSelection(.previous)])
  }

  func testStationaryChangedFramesProduceNoCommand() {
    var recognizer = SwitcherGestureRecognizer()
    _ = recognizer.consume(frame(y: 0.5))
    _ = recognizer.consume(frame(y: 0.54))

    XCTAssertEqual(recognizer.consume(frame(y: 0.54)), [])
  }

  func testNewGestureDoesNotReuseMovementFromThePreviousGesture() {
    var recognizer = SwitcherGestureRecognizer()
    _ = recognizer.consume(frame(y: 0.5))
    _ = recognizer.consume(frame(y: 0.5 + SwitcherGestureRecognizer.rowDistance))
    XCTAssertEqual(recognizer.consume(frame(ids: [1, 2], y: 0.5)), [.activateSwitcherSelection])

    XCTAssertEqual(recognizer.consume(frame(y: 0.5)), [.openSwitcher])
    XCTAssertEqual(recognizer.consume(frame(y: 0.54)), [])
  }

  func testLiftingAllFingersActivatesTheSelection() {
    var recognizer = SwitcherGestureRecognizer()
    _ = recognizer.consume(frame(y: 0.5))

    XCTAssertEqual(recognizer.consume(frame(ids: [1, 2], y: 0.5)), [.activateSwitcherSelection])
  }

  func testSwipeUpOpensTheSwitcherOnlyAfterCrossingTheActivationDistance() {
    var recognizer = SwitcherGestureRecognizer(activation: .swipeUp)

    XCTAssertEqual(recognizer.consume(frame(y: 0.5)), [])
    XCTAssertEqual(
      recognizer.consume(frame(y: 0.5 + SwitcherGestureRecognizer.activationDistance / 2)), [])
    XCTAssertEqual(
      recognizer.consume(frame(y: 0.5 + SwitcherGestureRecognizer.activationDistance)),
      [.openSwitcher])
  }

  func testSwipeDownOpensTheSwitcherOnlyAfterCrossingTheActivationDistance() {
    var recognizer = SwitcherGestureRecognizer(activation: .swipeDown)

    XCTAssertEqual(recognizer.consume(frame(y: 0.5)), [])
    XCTAssertEqual(
      recognizer.consume(frame(y: 0.5 - SwitcherGestureRecognizer.activationDistance / 2)), [])
    XCTAssertEqual(
      recognizer.consume(frame(y: 0.5 - SwitcherGestureRecognizer.activationDistance)),
      [.openSwitcher])
  }

  func testSwipeActivationPreservesSelectionNavigationForLaterMovement() {
    var recognizer = SwitcherGestureRecognizer(activation: .swipeUp)
    _ = recognizer.consume(frame(y: 0.5))

    XCTAssertEqual(
      recognizer.consume(frame(y: 0.5 + SwitcherGestureRecognizer.activationDistance)),
      [.openSwitcher])
    XCTAssertEqual(
      recognizer.consume(
        frame(
          y: 0.5 + SwitcherGestureRecognizer.activationDistance
            + SwitcherGestureRecognizer.rowDistance)),
      [.moveSwitcherSelection(.previous)])
  }

  func testSwipeInTheOppositeDirectionDoesNotOpenTheSwitcher() {
    var recognizer = SwitcherGestureRecognizer(activation: .swipeUp)
    _ = recognizer.consume(frame(y: 0.5))

    XCTAssertEqual(
      recognizer.consume(frame(y: 0.5 - SwitcherGestureRecognizer.activationDistance)), [])
    XCTAssertEqual(recognizer.consume(frame(ids: [1, 2], y: 0.5)), [])
  }

  func testHigherActivationSensitivityOpensWithMovementThatDoesNotOpenAtLowerSensitivity() {
    var highSensitivity = SwitcherGestureRecognizer(
      activation: .swipeUp,
      activationSensitivity: .highest)
    var lowSensitivity = SwitcherGestureRecognizer(
      activation: .swipeUp,
      activationSensitivity: .lowest)

    _ = highSensitivity.consume(frame(y: 0.5))
    _ = lowSensitivity.consume(frame(y: 0.5))

    XCTAssertEqual(highSensitivity.consume(frame(y: 0.608)), [.openSwitcher])
    XCTAssertEqual(lowSensitivity.consume(frame(y: 0.608)), [])
  }

  func testUntriggeredSwipeDoesNotActivateThePickerWhenFingersLift() {
    var recognizer = SwitcherGestureRecognizer(activation: .swipeUp)

    _ = recognizer.consume(frame(y: 0.5))

    XCTAssertEqual(recognizer.consume(frame(ids: [1, 2], y: 0.5)), [])
  }

  private func frame(count: Int = 3, y: Float) -> TouchFrame {
    frame(ids: (0..<count).map { Int32($0 + 1) }, y: y)
  }

  private func frame(ids: [Int32], y: Float) -> TouchFrame {
    TouchFrame(
      contacts: ids.enumerated().map { index, id in
        let x = Float(index + 1) / Float(ids.count + 1)
        return TouchContact(id: id, x: x, y: y)
      })
  }
}
