import XCTest

@testable import TouchpadWM

final class AccessibilityWindowMetadataTests: XCTestCase {
  func testClassifiesRolesWithoutAccessibilityHardware() {
    XCTAssertEqual(AccessibilityWindowMetadata.role(role: "AXWindow", subrole: nil), .normal)
    XCTAssertEqual(AccessibilityWindowMetadata.role(role: "AXSheet", subrole: nil), .sheet)
    XCTAssertEqual(
      AccessibilityWindowMetadata.role(role: "AXWindow", subrole: "AXFloatingWindow"), .floating)
  }
}
