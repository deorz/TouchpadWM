import Foundation
import XCTest

@testable import TouchpadWM

@MainActor
final class AccessibilityPermissionTests: XCTestCase {
  func testRefreshUpdatesPermissionFromSource() {
    let source = PermissionSource(isTrusted: false)
    let state = AppState(permissionChecker: source)

    XCTAssertEqual(state.accessibilityPermission, .unavailable)

    source.trusted = true
    state.refreshAccessibilityPermission()

    XCTAssertEqual(state.accessibilityPermission, .available)
  }

  func testAutomaticallyRefreshesPermissionStatus() {
    let source = PermissionSource(isTrusted: false)
    let state = AppState(permissionChecker: source)

    source.trusted = true
    RunLoop.main.run(until: Date().addingTimeInterval(2.2))

    XCTAssertEqual(state.accessibilityPermission, .available)
  }

  func testOpeningSettingsDoesNotChangeUnavailablePermission() {
    let source = PermissionSource(isTrusted: false, opensSettings: false)
    let state = AppState(permissionChecker: source)

    state.openAccessibilitySettings()

    XCTAssertEqual(state.accessibilityPermission, .unavailable)
  }
}

private final class PermissionSource: AccessibilityPermissionChecking {
  var trusted: Bool
  let opensSettings: Bool

  init(isTrusted: Bool, opensSettings: Bool = true) {
    trusted = isTrusted
    self.opensSettings = opensSettings
  }

  func isTrusted() -> Bool {
    trusted
  }

  func openSettings() -> Bool {
    opensSettings
  }
}
