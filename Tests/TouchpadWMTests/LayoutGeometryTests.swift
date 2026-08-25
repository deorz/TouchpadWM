import CoreGraphics
import XCTest

@testable import TouchpadWM

final class LayoutGeometryTests: XCTestCase {
  func testMasterStackInsetsEveryVisibleFrameEdge() {
    XCTAssertEqual(
      LayoutGeometry.frame(for: .masterStack, in: CGRect(x: 0, y: 0, width: 1000, height: 800)),
      CGRect(x: 8, y: 8, width: 984, height: 784))
  }

  func testHalvesAndThreeQuarterZonesLeaveTheFixedGapAtTheirSharedBoundary() {
    let frame = CGRect(x: 100, y: 50, width: 1000, height: 800)

    XCTAssertEqual(
      LayoutGeometry.frame(for: .leftHalf, in: frame),
      CGRect(x: 108, y: 58, width: 488, height: 784))
    XCTAssertEqual(
      LayoutGeometry.frame(for: .rightHalf, in: frame),
      CGRect(x: 604, y: 58, width: 488, height: 784))
    XCTAssertEqual(
      LayoutGeometry.frame(for: .leftThreeQuarters, in: frame),
      CGRect(x: 108, y: 58, width: 732, height: 784))
    XCTAssertEqual(
      LayoutGeometry.frame(for: .rightQuarter, in: frame),
      CGRect(x: 848, y: 58, width: 244, height: 784))
  }

  func testBSPRightZonesUseAXScreenCoordinates() {
    let frame = CGRect(x: 0, y: 0, width: 1000, height: 800)

    XCTAssertEqual(
      LayoutGeometry.frame(for: .topRightQuarter, in: frame),
      CGRect(x: 504, y: 8, width: 488, height: 388))
    XCTAssertEqual(
      LayoutGeometry.frame(for: .bottomRightQuarter, in: frame),
      CGRect(x: 504, y: 404, width: 488, height: 388))
  }

  func testEveryKeyboardLayoutCommandHasItsSpecifiedZone() {
    XCTAssertEqual(LayoutCommand.leftHalf.zone, .leftHalf)
    XCTAssertEqual(LayoutCommand.rightHalf.zone, .rightHalf)
    XCTAssertEqual(LayoutCommand.leftThreeQuarters.zone, .leftThreeQuarters)
    XCTAssertEqual(LayoutCommand.rightQuarter.zone, .rightQuarter)
    XCTAssertEqual(LayoutCommand.topRightQuarter.zone, .topRightQuarter)
    XCTAssertEqual(LayoutCommand.bottomRightQuarter.zone, .bottomRightQuarter)
    XCTAssertEqual(LayoutCommand.masterStack.zone, .masterStack)
  }
}
