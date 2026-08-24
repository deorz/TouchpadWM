import XCTest

@testable import TouchpadWM

final class KeyboardCommandsTests: XCTestCase {
  func testRightOptionWithArrowMapsFixedCommands() {
    var interpreter = KeyboardCommandInterpreter()

    XCTAssertNil(interpreter.consume(.flagsChanged(keyCode: 61)))
    XCTAssertEqual(interpreter.consume(.keyDown(keyCode: 123, shiftIsPressed: false)), .leftHalf)
    XCTAssertEqual(interpreter.consume(.keyDown(keyCode: 124, shiftIsPressed: false)), .rightHalf)
    XCTAssertEqual(
      interpreter.consume(.keyDown(keyCode: 126, shiftIsPressed: false)), .topRightQuarter)
    XCTAssertEqual(
      interpreter.consume(.keyDown(keyCode: 125, shiftIsPressed: false)), .bottomRightQuarter)
    XCTAssertEqual(
      interpreter.consume(.keyDown(keyCode: 123, shiftIsPressed: true)), .leftThreeQuarters)
    XCTAssertEqual(interpreter.consume(.keyDown(keyCode: 124, shiftIsPressed: true)), .rightQuarter)
    XCTAssertEqual(interpreter.consume(.keyDown(keyCode: 126, shiftIsPressed: true)), .masterStack)
    XCTAssertNil(interpreter.consume(.keyDown(keyCode: 125, shiftIsPressed: true)))
  }

  func testLeftOptionDoesNotEnableCommands() {
    var interpreter = KeyboardCommandInterpreter()

    XCTAssertNil(interpreter.consume(.flagsChanged(keyCode: 58)))
    XCTAssertNil(interpreter.consume(.keyDown(keyCode: 123, shiftIsPressed: false)))
  }

  func testRouterBlocksUnavailablePermissionAndDispatchesAvailableCommand() {
    var router = KeyboardCommandRouter()
    var commands: [LayoutCommand] = []

    _ = router.consume(.flagsChanged(keyCode: 61), permission: .unavailable) { commands.append($0) }
    XCTAssertFalse(
      router.consume(.keyDown(keyCode: 123, shiftIsPressed: false), permission: .unavailable) {
        commands.append($0)
      })
    XCTAssertEqual(commands, [])

    XCTAssertTrue(
      router.consume(.keyDown(keyCode: 123, shiftIsPressed: false), permission: .available) {
        commands.append($0)
      })
    XCTAssertEqual(commands, [.leftHalf])
  }
}
