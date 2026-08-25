@testable import TouchpadWM

/// Shared `AccessibilityPermissionChecking` fake for every test that needs an `AppState`.
final class PermissionSource: AccessibilityPermissionChecking {
  var trusted: Bool
  let opensSettings: Bool
  private(set) var isTrustedCallCount = 0

  init(isTrusted: Bool, opensSettings: Bool = true) {
    trusted = isTrusted
    self.opensSettings = opensSettings
  }

  func isTrusted() -> Bool {
    isTrustedCallCount += 1
    return trusted
  }

  func openSettings() -> Bool {
    opensSettings
  }
}
