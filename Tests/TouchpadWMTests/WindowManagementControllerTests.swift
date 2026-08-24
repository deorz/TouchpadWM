import CoreGraphics
import XCTest

@testable import TouchpadWM

final class WindowManagementControllerTests: XCTestCase {
  func testApplyingAZoneMovesOnlyTheFocusedManagedWindow() {
    let service = InMemoryWindowService(
      windows: [focusedNormalWindow, unrelatedNormalWindow], focusedID: focusedNormalWindow.id)
    let controller = WindowManagementController(service: service)

    XCTAssertEqual(controller.apply(.rightHalf), .applied)
    XCTAssertEqual(
      service.appliedFrames,
      [focusedNormalWindow.id: CGRect(x: 504, y: 8, width: 488, height: 784)])
  }

  func testNoFocusedManagedWindowDoesNotApplyAnyFrame() {
    let service = InMemoryWindowService(windows: [utilityWindow], focusedID: utilityWindow.id)
    let controller = WindowManagementController(service: service)

    XCTAssertEqual(controller.apply(.masterStack), .noFocusedManagedWindow)
    XCTAssertTrue(service.appliedFrames.isEmpty)
  }

  func testInaccessibleFocusedWindowReportsFailureWithoutMovingAnotherWindow() {
    let service = InMemoryWindowService(
      windows: [focusedNormalWindow, unrelatedNormalWindow],
      focusedID: focusedNormalWindow.id,
      acceptsMutations: false)
    let controller = WindowManagementController(service: service)

    XCTAssertEqual(controller.apply(.leftHalf), .inaccessibleWindow)
    XCTAssertTrue(service.appliedFrames.isEmpty)
  }

  private var focusedNormalWindow: CataloguedWindow {
    window(id: 1, role: .normal)
  }

  private var unrelatedNormalWindow: CataloguedWindow {
    window(id: 2, role: .normal)
  }

  private var utilityWindow: CataloguedWindow {
    window(id: 3, role: .utility)
  }

  private func window(id: CGWindowID, role: WindowRole) -> CataloguedWindow {
    CataloguedWindow(
      id: WindowID(processIdentifier: 1, windowNumber: id),
      bundleIdentifier: "com.example.app",
      title: "Window \(id)",
      role: role,
      isMinimized: false,
      visibleFrame: CGRect(x: 0, y: 0, width: 1000, height: 800))
  }
}

private final class InMemoryWindowService: AccessibilityWindowServicing {
  let windows: [CataloguedWindow]
  let focusedID: WindowID?
  let acceptsMutations: Bool
  private(set) var appliedFrames: [WindowID: CGRect] = [:]

  init(windows: [CataloguedWindow], focusedID: WindowID?, acceptsMutations: Bool = true) {
    self.windows = windows
    self.focusedID = focusedID
    self.acceptsMutations = acceptsMutations
  }

  func refreshWindows() -> [CataloguedWindow] {
    windows
  }

  func focusedWindowID() -> WindowID? {
    focusedID
  }

  func apply(_ frame: CGRect, to id: WindowID) -> Bool {
    guard acceptsMutations else {
      return false
    }
    appliedFrames[id] = frame
    return true
  }
}
