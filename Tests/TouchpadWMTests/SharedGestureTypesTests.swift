import TouchpadWMSpike
import XCTest

@testable import TouchpadWM

final class SharedGestureTypesTests: XCTestCase {
  func testTouchpadWMCanDriveTheSharedRecognizerAcrossThreeFingerContacts() {
    var recognizer = ThreeFingerGestureRecognizer()
    let frame = TouchFrame(contacts: [
      TouchContact(id: 1, x: 0.2, y: 0.2),
      TouchContact(id: 2, x: 0.5, y: 0.2),
      TouchContact(id: 3, x: 0.8, y: 0.2),
    ])

    XCTAssertEqual(recognizer.consume(frame), [.began])
  }
}
