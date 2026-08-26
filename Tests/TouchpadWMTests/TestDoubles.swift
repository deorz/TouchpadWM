@testable import TouchpadWM

/// Shared in-memory `AppRuleStoring` fake for tests that need a `WindowPickerController`.
final class InMemoryAppRuleStore: AppRuleStoring {
  private var rules: [String: AppRule]

  init(_ rules: [String: AppRule] = [:]) {
    self.rules = rules
  }

  func rule(for bundleIdentifier: String) -> AppRule {
    rules[bundleIdentifier] ?? .included
  }

  func setRule(_ rule: AppRule, for bundleIdentifier: String) {
    rules[bundleIdentifier] = rule
  }
}

final class PermissionSource: AccessibilityPermissionChecking {
  var trusted: Bool
  let opensSettings: Bool
  private(set) var isTrustedCallCount = 0
  private(set) var requestTrustCallCount = 0

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

  func requestTrust() {
    requestTrustCallCount += 1
  }

}
