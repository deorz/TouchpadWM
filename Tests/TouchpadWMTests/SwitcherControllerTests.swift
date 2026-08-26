import CoreGraphics
import XCTest

@testable import TouchpadWM

final class SwitcherControllerTests: XCTestCase {
  func testOpenWithNoEligibleWindowsProducesNoSession() {
    let windowSource = FakeSwitcherWindowSourcing(windows: [])
    let controller = SwitcherController(windowSource: windowSource)

    controller.open()

    XCTAssertNil(controller.session)
  }

  func testOpenSnapshotsTheMRUOrderWithTheCurrentWindowSelected() {
    let windowSource = FakeSwitcherWindowSourcing(windows: [windowA, windowB])
    let controller = SwitcherController(windowSource: windowSource)

    controller.open()

    XCTAssertEqual(controller.session?.windows.map(\.id), [windowA.id, windowB.id])
    XCTAssertEqual(controller.session?.selectedIndex, 0)
    XCTAssertEqual(controller.session?.selectedWindow?.id, windowA.id)
  }

  func testMovingPreviousClampsAtTheOldestWindow() {
    let windowSource = FakeSwitcherWindowSourcing(windows: [windowA, windowB])
    let controller = SwitcherController(windowSource: windowSource)
    controller.open()

    controller.moveSelection(.previous)
    controller.moveSelection(.previous)

    XCTAssertEqual(controller.session?.selectedIndex, 1)
  }

  func testMovingNextClampsAtTheCurrentWindow() {
    let windowSource = FakeSwitcherWindowSourcing(windows: [windowA, windowB])
    let controller = SwitcherController(windowSource: windowSource)
    controller.open()

    controller.moveSelection(.next)

    XCTAssertEqual(controller.session?.selectedIndex, 0)
  }

  func testActivatingTheSelectionMarksItFocusedAndClosesTheSession() {
    let windowSource = FakeSwitcherWindowSourcing(windows: [windowA, windowB])
    let controller = SwitcherController(windowSource: windowSource)
    controller.open()
    controller.moveSelection(.previous)

    XCTAssertTrue(controller.activateSelection())

    XCTAssertEqual(windowSource.activatedIDs, [windowB.id])
    XCTAssertEqual(windowSource.markedFocusedIDs, [windowB.id])
    XCTAssertNil(controller.session)
  }

  func testActivationFailureClosesTheSessionWithoutMarkingFocus() {
    let windowSource = FakeSwitcherWindowSourcing(windows: [windowA], activationSucceeds: false)
    let controller = SwitcherController(windowSource: windowSource)
    controller.open()

    XCTAssertFalse(controller.activateSelection())

    XCTAssertTrue(windowSource.markedFocusedIDs.isEmpty)
    XCTAssertNil(controller.session)
  }

  func testCancelClosesTheSessionWithoutActivating() {
    let windowSource = FakeSwitcherWindowSourcing(windows: [windowA])
    let controller = SwitcherController(windowSource: windowSource)
    controller.open()

    controller.cancel()

    XCTAssertNil(controller.session)
    XCTAssertTrue(windowSource.activatedIDs.isEmpty)
  }

  private var windowA: CataloguedWindow {
    window(id: 1)
  }

  private var windowB: CataloguedWindow {
    window(id: 2)
  }

  private func window(id: CGWindowID) -> CataloguedWindow {
    CataloguedWindow(
      id: WindowID(processIdentifier: 1, windowNumber: id),
      bundleIdentifier: "com.example.app",
      applicationName: "Example App",
      title: "Window \(id)",
      role: .normal,
      isMinimized: false,
      visibleFrame: CGRect(x: 0, y: 0, width: 1000, height: 800))
  }
}

private final class FakeSwitcherWindowSourcing: SwitcherWindowSourcing {
  private let windows: [CataloguedWindow]
  private let activationSucceeds: Bool
  private(set) var activatedIDs: [WindowID] = []
  private(set) var markedFocusedIDs: [WindowID] = []

  init(windows: [CataloguedWindow], activationSucceeds: Bool = true) {
    self.windows = windows
    self.activationSucceeds = activationSucceeds
  }

  func refreshedWindowsForSwitcher() -> [CataloguedWindow] {
    windows
  }

  func markWindowFocused(_ id: WindowID) {
    markedFocusedIDs.append(id)
  }

  func activate(_ id: WindowID) -> Bool {
    guard activationSucceeds else {
      return false
    }
    activatedIDs.append(id)
    return true
  }
}
