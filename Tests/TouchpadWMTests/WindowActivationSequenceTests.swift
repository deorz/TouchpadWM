import XCTest

@testable import TouchpadWM

final class WindowActivationSequenceTests: XCTestCase {
  func testActivatesApplicationBeforeRaisingAndFocusingWindow() {
    var events: [String] = []

    let didActivateWindow = WindowActivationSequence.perform(
      activateApplication: { events.append("activate application") },
      raiseWindow: {
        events.append("raise window")
        return true
      },
      focusWindow: {
        events.append("focus window")
        return true
      })

    XCTAssertTrue(didActivateWindow)
    XCTAssertEqual(events, ["activate application", "raise window", "focus window"])
  }
}
