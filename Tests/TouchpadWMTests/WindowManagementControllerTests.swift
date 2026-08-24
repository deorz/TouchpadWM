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

  @MainActor
  func testAvailableAppStateDelegatesLayoutCommandToTheController() {
    let controller = RecordingWindowManager(result: .applied)
    let state = AppState(permissionChecker: PermissionSource(isTrusted: true), windowManagement: controller)

    state.performLayoutCommand(.rightHalf)

    XCTAssertEqual(controller.receivedZones, [.rightHalf])
    XCTAssertEqual(state.windowManagementStatus, "Applied right half layout.")
  }

  @MainActor
  func testUnavailableAppStateDoesNotDelegateLayoutCommand() {
    let controller = RecordingWindowManager(result: .applied)
    let state = AppState(permissionChecker: PermissionSource(isTrusted: false), windowManagement: controller)

    state.performLayoutCommand(.masterStack)

    XCTAssertTrue(controller.receivedZones.isEmpty)
    XCTAssertEqual(state.windowManagementStatus, "Accessibility access is required.")
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

private final class PermissionSource: AccessibilityPermissionChecking {
  let trusted: Bool

  init(isTrusted: Bool) {
    trusted = isTrusted
  }

  func isTrusted() -> Bool {
    trusted
  }

  func openSettings() -> Bool {
    true
  }
}

private final class RecordingWindowManager: WindowManaging {
  let result: LayoutOperationResult
  private(set) var receivedZones: [LayoutZone] = []

  init(result: LayoutOperationResult) {
    self.result = result
  }

  func apply(_ zone: LayoutZone) -> LayoutOperationResult {
    receivedZones.append(zone)
    return result
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
