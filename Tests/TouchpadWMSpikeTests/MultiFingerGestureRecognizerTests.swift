import XCTest

@testable import TouchpadWMSpike

final class MultiFingerGestureRecognizerTests: XCTestCase {
  func testRequiredContactsBeginAndMovingUpReportsPositiveDistance() {
    var recognizer = MultiFingerGestureRecognizer()

    XCTAssertEqual(recognizer.consume(frame(ids: [1, 2, 3], y: 0.2)), [.began])
    XCTAssertEqual(
      recognizer.consume(frame(ids: [1, 2, 3], y: 0.5)),
      [.changed(totalVerticalMovement: 0.3)]
    )
  }

  func testTwoContactsProduceNoEvent() {
    var recognizer = MultiFingerGestureRecognizer()

    XCTAssertEqual(recognizer.consume(frame(ids: [1, 2], y: 0.2)), [])
  }

  func testRemovingOneTrackedFingerEmitsEndedOnce() {
    var recognizer = MultiFingerGestureRecognizer()

    XCTAssertEqual(recognizer.consume(frame(ids: [1, 2, 3], y: 0.2)), [.began])
    XCTAssertEqual(recognizer.consume(frame(ids: [1, 2], y: 0.5)), [.ended])
  }

  private func frame(ids: [Int32], y: Float) -> TouchFrame {
    TouchFrame(
      contacts: zip(ids, [Float](arrayLiteral: 0.2, 0.5, 0.8)).map { id, x in
        TouchContact(id: id, x: x, y: y)
      }
    )
  }
}
