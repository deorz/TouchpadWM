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
    let state = AppState(permissionChecker: source, refreshInterval: 0.03)

    source.trusted = true
    RunLoop.main.run(until: Date().addingTimeInterval(0.1))

    XCTAssertEqual(state.accessibilityPermission, .available)
  }

  func testDoesNotPollWhenAlreadyTrustedAtInit() {
    let source = PermissionSource(isTrusted: true)
    _ = AppState(permissionChecker: source, refreshInterval: 0.03)

    RunLoop.main.run(until: Date().addingTimeInterval(0.1))

    XCTAssertEqual(source.isTrustedCallCount, 1)
  }

  func testRequestsTrustPromptOnceAtInitWhenNotYetTrusted() {
    let source = PermissionSource(isTrusted: false)

    _ = AppState(permissionChecker: source)

    XCTAssertEqual(source.requestTrustCallCount, 1)
  }

  func testDoesNotRequestTrustPromptWhenAlreadyTrustedAtInit() {
    let source = PermissionSource(isTrusted: true)

    _ = AppState(permissionChecker: source)

    XCTAssertEqual(source.requestTrustCallCount, 0)
  }

  func testStopsPollingOnceAccessBecomesAvailable() {
    let source = PermissionSource(isTrusted: false)
    let state = AppState(permissionChecker: source, refreshInterval: 0.03)

    source.trusted = true
    RunLoop.main.run(until: Date().addingTimeInterval(0.1))
    XCTAssertEqual(state.accessibilityPermission, .available)

    let callCountAfterGranted = source.isTrustedCallCount
    RunLoop.main.run(until: Date().addingTimeInterval(0.1))

    XCTAssertEqual(source.isTrustedCallCount, callCountAfterGranted)
  }
}
