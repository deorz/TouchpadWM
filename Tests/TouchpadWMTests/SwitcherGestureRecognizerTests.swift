import TouchpadWMSpike
import XCTest

@testable import TouchpadWM

final class SwitcherGestureRecognizerTests: XCTestCase {
  func testThreeFingerContactImmediatelyOpensTheSwitcher() {
    var recognizer = SwitcherGestureRecognizer()

    XCTAssertEqual(recognizer.consume(frame(y: 0.5)), [.openSwitcher])
  }

  func testCrossingOneThresholdUpwardMovesToThePreviousRow() {
    var recognizer = SwitcherGestureRecognizer()
    _ = recognizer.consume(frame(y: 0.5))

    let commands = recognizer.consume(
      frame(y: 0.5 + SwitcherGestureRecognizer.rowSelectionThreshold))

    XCTAssertEqual(commands, [.moveSwitcherSelection(.previous)])
  }

  func testMovingBackBelowTheThresholdMovesToTheNextRow() {
    var recognizer = SwitcherGestureRecognizer()
    _ = recognizer.consume(frame(y: 0.5))
    _ = recognizer.consume(frame(y: 0.5 + SwitcherGestureRecognizer.rowSelectionThreshold))

    let commands = recognizer.consume(frame(y: 0.5))

    XCTAssertEqual(commands, [.moveSwitcherSelection(.next)])
  }

  func testSubThresholdMovementProducesNoCommand() {
    var recognizer = SwitcherGestureRecognizer()
    _ = recognizer.consume(frame(y: 0.5))

    let commands = recognizer.consume(
      frame(y: 0.5 + SwitcherGestureRecognizer.rowSelectionThreshold / 2))

    XCTAssertEqual(commands, [])
  }

  func testCrossingTwoThresholdsInOneFrameEmitsTwoMoveCommands() {
    var recognizer = SwitcherGestureRecognizer()
    _ = recognizer.consume(frame(y: 0.5))

    let commands = recognizer.consume(
      frame(y: 0.5 + 2 * SwitcherGestureRecognizer.rowSelectionThreshold))

    XCTAssertEqual(
      commands, [.moveSwitcherSelection(.previous), .moveSwitcherSelection(.previous)])
  }

  func testLiftingAllFingersActivatesTheSelection() {
    var recognizer = SwitcherGestureRecognizer()
    _ = recognizer.consume(frame(y: 0.5))

    let commands = recognizer.consume(frame(ids: [1, 2], y: 0.5))

    XCTAssertEqual(commands, [.activateSwitcherSelection])
  }

  private func frame(ids: [Int32] = [1, 2, 3], y: Float) -> TouchFrame {
    TouchFrame(
      contacts: zip(ids, [Float](arrayLiteral: 0.2, 0.5, 0.8)).map { id, x in
        TouchContact(id: id, x: x, y: y)
      })
  }
}
