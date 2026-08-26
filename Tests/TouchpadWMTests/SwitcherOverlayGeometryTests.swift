import CoreGraphics
import XCTest

@testable import TouchpadWM

final class SwitcherOverlayGeometryTests: XCTestCase {
  func testPanelSizeUsesOneCompactRowForASingleWindow() {
    XCTAssertEqual(
      SwitcherOverlayGeometry.panelSize(forWindowCount: 1),
      CGSize(width: 360, height: 80))
  }

  func testPanelSizeCapsItsHeightAtFiveVisibleRows() {
    XCTAssertEqual(
      SwitcherOverlayGeometry.panelSize(forWindowCount: 9),
      CGSize(width: 360, height: 304))
  }

  func testOriginCentersThePanelWithinTheScreenFrame() {
    let screenFrame = CGRect(x: 0, y: 0, width: 1000, height: 800)
    let panelSize = CGSize(width: 280, height: 200)

    let origin = SwitcherOverlayGeometry.origin(
      forPanelSize: panelSize, centeredIn: screenFrame)

    XCTAssertEqual(origin, CGPoint(x: 360, y: 300))
  }

  func testOriginCentersTheCappedPickerOnAnOffsetScreenFrame() {
    let screenFrame = CGRect(x: 100, y: 50, width: 1000, height: 800)
    let panelSize = SwitcherOverlayGeometry.panelSize(forWindowCount: 9)

    let origin = SwitcherOverlayGeometry.origin(
      forPanelSize: panelSize, centeredIn: screenFrame)

    XCTAssertEqual(origin, CGPoint(x: 420, y: 298))
  }
}
