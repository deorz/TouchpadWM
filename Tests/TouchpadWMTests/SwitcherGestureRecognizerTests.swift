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
      (PickerTrigger.threeFingers, 3),
      (PickerTrigger.fourFingers, 4),
      (PickerTrigger.fiveFingers, 5),
    ] {
      var recognizer = SwitcherGestureRecognizer(trigger: trigger)

      XCTAssertEqual(
        recognizer.consume(frame(count: count, y: 0.5)),
        [.openSwitcher],
        "Expected \(count)-finger trigger to open the switcher")
    }
  }

  func testConfiguredFingerCountIgnoresOtherContactCounts() {
    var recognizer = SwitcherGestureRecognizer(trigger: .fourFingers)

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
    recognizer.update(trigger: .fiveFingers, sensitivity: .highest)

    XCTAssertEqual(recognizer.consume(frame(count: 5, y: 0.5)), [.openSwitcher])
  }

  func testKeepingTheSameConfigurationDoesNotResetAnActiveGesture() {
    var recognizer = SwitcherGestureRecognizer()
    _ = recognizer.consume(frame(y: 0.5))
    recognizer.update(trigger: .threeFingers, sensitivity: .medium)

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
