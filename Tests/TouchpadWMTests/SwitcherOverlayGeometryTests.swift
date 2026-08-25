import CoreGraphics
import XCTest

@testable import TouchpadWM

final class SwitcherOverlayGeometryTests: XCTestCase {
  func testOriginCentersThePanelWithinTheScreenFrame() {
    let screenFrame = CGRect(x: 0, y: 0, width: 1000, height: 800)
    let panelSize = CGSize(width: 280, height: 200)

    let origin = SwitcherOverlayGeometry.origin(
      forPanelSize: panelSize, centeredIn: screenFrame)

    XCTAssertEqual(origin, CGPoint(x: 360, y: 300))
  }

  func testOriginAccountsForAnOffsetScreenFrame() {
    let screenFrame = CGRect(x: 100, y: 50, width: 1000, height: 800)
    let panelSize = CGSize(width: 280, height: 200)

    let origin = SwitcherOverlayGeometry.origin(
      forPanelSize: panelSize, centeredIn: screenFrame)

    XCTAssertEqual(origin, CGPoint(x: 460, y: 350))
  }
}
