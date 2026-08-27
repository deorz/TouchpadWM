import CoreGraphics
import XCTest

@testable import TouchpadWM

@MainActor
final class SwitcherOverlayModelTests: XCTestCase {
  func testShowPublishesANewSession() {
    let model = SwitcherOverlayModel()
    let session = makeSession(windowIDs: [1, 2], selectedIndex: 0)

    model.show(session)

    XCTAssertEqual(model.session, session)
  }

  func testShowReplacesTheSessionForASelectionUpdate() {
    let model = SwitcherOverlayModel()
    model.show(makeSession(windowIDs: [1, 2], selectedIndex: 0))
    let updated = makeSession(windowIDs: [1, 2], selectedIndex: 1)

    model.show(updated)

    XCTAssertEqual(model.session, updated)
  }

  func testShowReplacesWindowsInTheActiveSession() {
    let model = SwitcherOverlayModel()
    model.show(makeSession(windowIDs: [1], selectedIndex: 0))
    let updated = makeSession(windowIDs: [2, 3], selectedIndex: 1)

    model.show(updated)

    XCTAssertEqual(model.session?.windows.map(\.id), updated.windows.map(\.id))
    XCTAssertEqual(model.session?.selectedIndex, 1)
  }

  func testHideClearsTheActiveSession() {
    let model = SwitcherOverlayModel()
    model.show(makeSession(windowIDs: [1], selectedIndex: 0))

    model.hide()

    XCTAssertNil(model.session)
  }

  private func makeSession(windowIDs: [CGWindowID], selectedIndex: Int) -> SwitcherSession {
    SwitcherSession(
      windows: windowIDs.map { id in
        CataloguedWindow(
          id: WindowID(processIdentifier: 1, windowNumber: id),
          bundleIdentifier: "com.example.app",
          applicationName: "Example App",
          title: "Window \(id)",
          role: .normal,
          isMinimized: false,
          visibleFrame: CGRect(x: 0, y: 0, width: 1000, height: 800))
      },
      selectedIndex: selectedIndex)
  }
}
