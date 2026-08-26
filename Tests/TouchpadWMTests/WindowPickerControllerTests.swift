import CoreGraphics
import XCTest

@testable import TouchpadWM

final class WindowPickerControllerTests: XCTestCase {
  func testStoredPickerExclusionAppliesOnTheNextSwitcherRefresh() {
    let window = makeWindow(id: 1)
    let service = InMemoryWindowService(windows: [window], focusedID: window.id)
    let store = InMemoryAppRuleStore([
      window.bundleIdentifier: .init(includeInSwitcher: false)
    ])
    let controller = WindowPickerController(service: service, ruleStore: store)

    XCTAssertTrue(controller.refreshedWindowsForSwitcher().isEmpty)
  }

  func testRefreshPlacesTheFocusedWindowFirstInMRUOrder() {
    let olderWindow = makeWindow(id: 1)
    let currentWindow = makeWindow(id: 2)
    let service = InMemoryWindowService(
      windows: [olderWindow, currentWindow], focusedID: currentWindow.id)
    let controller = WindowPickerController(service: service)

    XCTAssertEqual(
      controller.refreshedWindowsForSwitcher().map(\.id),
      [currentWindow.id, olderWindow.id])
  }

  func testActivatingSelectionUpdatesTheNextPickerSessionMRU() {
    let olderWindow = makeWindow(id: 1)
    let currentWindow = makeWindow(id: 2)
    let service = InMemoryWindowService(
      windows: [olderWindow, currentWindow], focusedID: currentWindow.id)
    let controller = WindowPickerController(service: service)
    _ = controller.refreshedWindowsForSwitcher()

    XCTAssertTrue(controller.activate(olderWindow.id))
    controller.markWindowFocused(olderWindow.id)

    XCTAssertEqual(controller.refreshedWindowsForSwitcher().first?.id, olderWindow.id)
  }

  private func makeWindow(id: CGWindowID) -> CataloguedWindow {
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

private final class InMemoryWindowService: AccessibilityWindowServicing {
  let windows: [CataloguedWindow]
  private(set) var focusedID: WindowID?
  private(set) var activatedIDs: [WindowID] = []

  init(windows: [CataloguedWindow], focusedID: WindowID?) {
    self.windows = windows
    self.focusedID = focusedID
  }

  func refreshWindows() -> [CataloguedWindow] {
    windows
  }

  func focusedWindowID() -> WindowID? {
    focusedID
  }

  func activate(_ id: WindowID) -> Bool {
    guard windows.contains(where: { $0.id == id }) else {
      return false
    }
    activatedIDs.append(id)
    focusedID = id
    return true
  }
}
