@testable import TouchpadWM

/// Shared `AccessibilityPermissionChecking` fake for every test that needs an `AppState`.
final class PermissionSource: AccessibilityPermissionChecking, InputMonitoringPermissionChecking {
  var trusted: Bool
  var inputMonitoringAccess: Bool
  let opensSettings: Bool
  private(set) var isTrustedCallCount = 0
  private(set) var inputMonitoringRequestCount = 0
  private(set) var requestTrustCallCount = 0

  init(
    isTrusted: Bool,
    inputMonitoringAccess: Bool = false,
    opensSettings: Bool = true
  ) {
    trusted = isTrusted
    self.inputMonitoringAccess = inputMonitoringAccess
    self.opensSettings = opensSettings
  }

  func isTrusted() -> Bool {
    isTrustedCallCount += 1
    return trusted
  }

  func openSettings() -> Bool {
    opensSettings
  }

  func requestTrust() {
    requestTrustCallCount += 1
  }

  func hasAccess() -> Bool {
    inputMonitoringAccess
  }

  func requestAccess() -> Bool {
    inputMonitoringRequestCount += 1
    return inputMonitoringAccess
  }
}
