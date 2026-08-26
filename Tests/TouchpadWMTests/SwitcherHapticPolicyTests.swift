import XCTest

@testable import TouchpadWM

final class SwitcherHapticPolicyTests: XCTestCase {
  func testOpeningTheSwitcherProducesGenericFeedback() {
    XCTAssertEqual(SwitcherHapticPolicy.feedback(for: .openSwitcher), .generic)
  }

  func testMovingToThePreviousRowProducesAlignmentFeedback() {
    XCTAssertEqual(
      SwitcherHapticPolicy.feedback(for: .moveSwitcherSelection(.previous)), .alignment)
  }

  func testMovingToTheNextRowProducesAlignmentFeedback() {
    XCTAssertEqual(
      SwitcherHapticPolicy.feedback(for: .moveSwitcherSelection(.next)), .alignment)
  }

  func testActivatingTheSelectionProducesGenericFeedback() {
    XCTAssertEqual(SwitcherHapticPolicy.feedback(for: .activateSwitcherSelection), .generic)
  }
}
