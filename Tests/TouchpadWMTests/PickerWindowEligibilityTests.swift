import CoreGraphics
import XCTest

@testable import TouchpadWM

final class PickerWindowEligibilityTests: XCTestCase {
  func testStandardWindowIsEligible() {
    XCTAssertTrue(
      PickerWindowEligibility.shouldInclude(
        bundleIdentifier: "com.example.editor",
        windowLayer: 0,
        frame: CGRect(x: 0, y: 0, width: 101, height: 51),
        accessibilitySubrole: "AXStandardWindow"))
  }

  func testDialogWindowIsEligible() {
    XCTAssertTrue(
      PickerWindowEligibility.shouldInclude(
        bundleIdentifier: "com.example.editor",
        windowLayer: 0,
        frame: CGRect(x: 0, y: 0, width: 500, height: 400),
        accessibilitySubrole: "AXDialog"))
  }

  func testNonNormalWindowServerLayerIsExcluded() {
    XCTAssertFalse(
      PickerWindowEligibility.shouldInclude(
        bundleIdentifier: "com.apple.notificationcenterui",
        windowLayer: 21,
        frame: CGRect(x: 0, y: 0, width: 500, height: 400),
        accessibilitySubrole: "AXStandardWindow"))
  }

  func testSmallWindowIsExcluded() {
    XCTAssertFalse(
      PickerWindowEligibility.shouldInclude(
        bundleIdentifier: "com.example.editor",
        windowLayer: 0,
        frame: CGRect(x: 0, y: 0, width: 100, height: 51),
        accessibilitySubrole: "AXStandardWindow"))
  }

  func testUniversalControlIsExcludedAtTheApplicationBoundary() {
    XCTAssertFalse(
      PickerWindowEligibility.shouldInclude(
        bundleIdentifier: "com.apple.universalcontrol",
        windowLayer: 0,
        frame: CGRect(x: 0, y: 0, width: 500, height: 400),
        accessibilitySubrole: "AXStandardWindow"))
  }

  func testFloatingWindowIsExcludedForEveryApplication() {
    XCTAssertFalse(
      PickerWindowEligibility.shouldInclude(
        bundleIdentifier: "com.google.Chrome",
        windowLayer: 0,
        frame: CGRect(x: 0, y: 0, width: 500, height: 80),
        accessibilitySubrole: "AXFloatingWindow"))
  }

  func testUtilityWindowIsExcludedForEveryApplication() {
    XCTAssertFalse(
      PickerWindowEligibility.shouldInclude(
        bundleIdentifier: "com.example.editor",
        windowLayer: 0,
        frame: CGRect(x: 0, y: 0, width: 500, height: 400),
        accessibilitySubrole: "AXUtilityWindow"))
  }

  func testUnknownSubroleIsExcludedForEveryApplication() {
    XCTAssertFalse(
      PickerWindowEligibility.shouldInclude(
        bundleIdentifier: "com.google.Chrome",
        windowLayer: 0,
        frame: CGRect(x: 0, y: 0, width: 1200, height: 800),
        accessibilitySubrole: "AXUnknown"))
  }

  func testMissingSubroleIsExcluded() {
    XCTAssertFalse(
      PickerWindowEligibility.shouldInclude(
        bundleIdentifier: "com.example.editor",
        windowLayer: 0,
        frame: CGRect(x: 0, y: 0, width: 1200, height: 800),
        accessibilitySubrole: nil))
  }
}
