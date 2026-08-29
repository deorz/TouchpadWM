import CoreGraphics
import XCTest

@testable import TouchpadWM

final class PickerWindowEligibilityTests: XCTestCase {
  func testNormalSizedApplicationWindowIsEligible() {
    XCTAssertTrue(
      PickerWindowEligibility.shouldInclude(
        bundleIdentifier: "com.example.editor",
        windowLayer: 0,
        frame: CGRect(x: 0, y: 0, width: 101, height: 51),
        role: .normal))
  }

  func testNonNormalWindowServerLayerIsExcluded() {
    XCTAssertFalse(
      PickerWindowEligibility.shouldInclude(
        bundleIdentifier: "com.apple.notificationcenterui",
        windowLayer: 21,
        frame: CGRect(x: 0, y: 0, width: 500, height: 400),
        role: .normal))
  }

  func testSmallWindowIsExcluded() {
    XCTAssertFalse(
      PickerWindowEligibility.shouldInclude(
        bundleIdentifier: "com.example.editor",
        windowLayer: 0,
        frame: CGRect(x: 0, y: 0, width: 100, height: 51),
        role: .normal))
  }

  func testUniversalControlIsExcludedAtTheApplicationBoundary() {
    XCTAssertFalse(
      PickerWindowEligibility.shouldInclude(
        bundleIdentifier: "com.apple.universalcontrol",
        windowLayer: 0,
        frame: CGRect(x: 0, y: 0, width: 500, height: 400),
        role: .normal))
  }

  func testChromeFloatingWindowIsExcludedFromPicker() {
    XCTAssertFalse(
      PickerWindowEligibility.shouldInclude(
        bundleIdentifier: "com.google.Chrome",
        windowLayer: 0,
        frame: CGRect(x: 0, y: 0, width: 500, height: 80),
        role: .floating))
  }

  func testNormalChromeWindowRemainsEligible() {
    XCTAssertTrue(
      PickerWindowEligibility.shouldInclude(
        bundleIdentifier: "com.google.Chrome",
        windowLayer: 0,
        frame: CGRect(x: 0, y: 0, width: 1200, height: 800),
        role: .normal))
  }
}
