import TouchpadWMSpike
import XCTest

@testable import TouchpadWM

final class SwitcherGestureRecognizerTests: XCTestCase {
  func testThreeFingerContactImmediatelyOpensTheSwitcher() {
    var recognizer = SwitcherGestureRecognizer()

    XCTAssertEqual(recognizer.consume(frame(y: 0.5)), [.openSwitcher])
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

  private func frame(ids: [Int32] = [1, 2, 3], y: Float) -> TouchFrame {
    TouchFrame(
      contacts: zip(ids, [Float](arrayLiteral: 0.2, 0.5, 0.8)).map { id, x in
        TouchContact(id: id, x: x, y: y)
      })
  }
}
