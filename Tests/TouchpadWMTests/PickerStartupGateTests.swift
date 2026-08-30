import XCTest

@testable import TouchpadWM

@MainActor
final class PickerStartupGateTests: XCTestCase {
  func testDoesNotStartPickerBeforeAccessibilityPermissionIsAvailable() {
    let gate = PickerStartupGate()
    var startCount = 0

    gate.startIfPermitted(.unavailable) {
      startCount += 1
    }

    XCTAssertEqual(startCount, 0)
  }

  func testStartsPickerOnceWhenAccessibilityPermissionBecomesAvailable() {
    let gate = PickerStartupGate()
    var startCount = 0

    gate.startIfPermitted(.unavailable) {
      startCount += 1
    }
    gate.startIfPermitted(.available) {
      startCount += 1
    }
    gate.startIfPermitted(.available) {
      startCount += 1
    }

    XCTAssertEqual(startCount, 1)
  }
}
