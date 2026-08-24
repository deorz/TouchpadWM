import XCTest

@testable import TouchpadWMSpike

final class MultitouchBridgeTests: XCTestCase {
  func testFrameFromRawSamplesPreservesIdentifiersAndPositions() {
    let frame = MultitouchBridge.frame(
      from: [RawTouchSample(id: 4, x: 0.25, y: 0.75)]
    )

    XCTAssertEqual(frame.contacts, [TouchContact(id: 4, x: 0.25, y: 0.75)])
  }
}
