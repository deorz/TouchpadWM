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
  func testAvailableAppStateMapsEachControllerResultToItsStatusText() {
    let cases: [(result: LayoutOperationResult, command: LayoutCommand, status: String)] = [
      (.applied, .rightHalf, "Applied right half layout."),
      (.noFocusedManagedWindow, .leftHalf, "No managed focused window."),
      (.inaccessibleWindow, .masterStack, "The focused window is not accessible."),
    ]

    for testCase in cases {
      let controller = RecordingWindowManager(result: testCase.result)
      let state = AppState(
        permissionChecker: PermissionSource(isTrusted: true), windowManagement: controller)

      state.performLayoutCommand(testCase.command)

      XCTAssertEqual(controller.receivedZones, [testCase.command.zone])
      XCTAssertEqual(state.windowManagementStatus, testCase.status)
    }
  }

  @MainActor
  func testUnavailableAppStateDoesNotDelegateLayoutCommand() {
    let controller = RecordingWindowManager(result: .applied)
    let state = AppState(
      permissionChecker: PermissionSource(isTrusted: false), windowManagement: controller)

    state.performLayoutCommand(.masterStack)

    XCTAssertTrue(controller.receivedZones.isEmpty)
    XCTAssertEqual(state.windowManagementStatus, "Accessibility access is required.")
  }

  func testStoredSwitcherExclusionAppliesOnTheNextSwitcherRefresh() {
    let service = InMemoryWindowService(windows: [focusedNormalWindow], focusedID: focusedNormalWindow.id)
    let store = InMemoryAppRuleStore([
      "com.example.app": .init(includeInSwitcher: false, manageLayout: true)
    ])
    let controller = WindowManagementController(service: service, ruleStore: store)

    XCTAssertTrue(controller.refreshedWindowsForSwitcher().isEmpty)
  }

  func testStoredLayoutExclusionMakesTheNextLayoutCommandHaveNoFocusedManagedWindow() {
    let service = InMemoryWindowService(windows: [focusedNormalWindow], focusedID: focusedNormalWindow.id)
    let store = InMemoryAppRuleStore([
      "com.example.app": .init(includeInSwitcher: true, manageLayout: false)
    ])
    let controller = WindowManagementController(service: service, ruleStore: store)

    XCTAssertEqual(controller.apply(.leftHalf), .noFocusedManagedWindow)
  }

  func testUpdatingARuleIsUsedByALaterSwitcherRefresh() {
    let service = InMemoryWindowService(windows: [focusedNormalWindow], focusedID: focusedNormalWindow.id)
    let store = InMemoryAppRuleStore()
    let controller = WindowManagementController(service: service, ruleStore: store)
    controller.setRule(
      .init(includeInSwitcher: false, manageLayout: true), for: "com.example.app")

    XCTAssertTrue(controller.refreshedWindowsForSwitcher().isEmpty)
  }

  func testActivatingAKnownWindowRecordsItAndActivatingAnUnknownWindowFails() {
    let service = InMemoryWindowService(
      windows: [focusedNormalWindow], focusedID: focusedNormalWindow.id)

    XCTAssertTrue(service.activate(focusedNormalWindow.id))
    XCTAssertEqual(service.activatedIDs, [focusedNormalWindow.id])
    XCTAssertFalse(service.activate(WindowID(processIdentifier: 999, windowNumber: 999)))
  }

  func testRefreshedWindowsForSwitcherReturnsMRUOrderWithTheFocusedWindowFirst() {
    let service = InMemoryWindowService(
      windows: [unrelatedNormalWindow, focusedNormalWindow], focusedID: focusedNormalWindow.id)
    let controller = WindowManagementController(service: service)

    let windows = controller.refreshedWindowsForSwitcher()

    XCTAssertEqual(windows.map(\.id), [focusedNormalWindow.id, unrelatedNormalWindow.id])
  }

  func testActivatingAWindowReordersASubsequentSwitcherRefresh() {
    // Mirrors the real production sequence (SwitcherController.activateSelection, Task 5):
    // activate() first (which, on the real AX service, changes what the live focused window
    // is), then markWindowFocused() to update the catalogue's MRU to match. Per the design
    // spec, MRU order updates only at switcher open and activation — the next open re-derives
    // focus from the live service, so this is what a subsequent refresh should reflect.
    let service = InMemoryWindowService(
      windows: [unrelatedNormalWindow, focusedNormalWindow], focusedID: focusedNormalWindow.id)
    let controller = WindowManagementController(service: service)
    _ = controller.refreshedWindowsForSwitcher()

    XCTAssertTrue(controller.activate(unrelatedNormalWindow.id))
    controller.markWindowFocused(unrelatedNormalWindow.id)
    let windows = controller.refreshedWindowsForSwitcher()

    XCTAssertEqual(windows.first?.id, unrelatedNormalWindow.id)
  }

  func testControllerActivateDelegatesToTheService() {
    let service = InMemoryWindowService(
      windows: [focusedNormalWindow], focusedID: focusedNormalWindow.id)
    let controller = WindowManagementController(service: service)

    XCTAssertTrue(controller.activate(focusedNormalWindow.id))
    XCTAssertEqual(service.activatedIDs, [focusedNormalWindow.id])
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
  private(set) var focusedID: WindowID?
  let acceptsMutations: Bool
  private(set) var appliedFrames: [WindowID: CGRect] = [:]
  private(set) var activatedIDs: [WindowID] = []

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

  func activate(_ id: WindowID) -> Bool {
    guard windows.contains(where: { $0.id == id }) else {
      return false
    }
    activatedIDs.append(id)
    focusedID = id
    return true
  }
}
