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

  func testDisabledHapticsProduceNoFeedback() {
    XCTAssertNil(
      SwitcherHapticPolicy.feedback(
        for: .moveSwitcherSelection(.next), strength: .off))
  }

  func testLightHapticsUseTheSubtlerPatternForEveryCommand() {
    XCTAssertEqual(
      SwitcherHapticPolicy.feedback(for: .openSwitcher, strength: .light), .alignment)
    XCTAssertEqual(
      SwitcherHapticPolicy.feedback(
        for: .moveSwitcherSelection(.next), strength: .light),
      .alignment)
    XCTAssertEqual(
      SwitcherHapticPolicy.feedback(
        for: .activateSwitcherSelection, strength: .light),
      .alignment)
  }

  func testStrongHapticsUseTheGenericPatternForEveryCommand() {
    XCTAssertEqual(
      SwitcherHapticPolicy.feedback(for: .openSwitcher, strength: .strong), .generic)
    XCTAssertEqual(
      SwitcherHapticPolicy.feedback(
        for: .moveSwitcherSelection(.next), strength: .strong),
      .generic)
    XCTAssertEqual(
      SwitcherHapticPolicy.feedback(
        for: .activateSwitcherSelection, strength: .strong),
      .generic)
  }
}
