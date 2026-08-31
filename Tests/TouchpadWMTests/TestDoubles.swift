import Foundation

@testable import TouchpadWM

/// Shared in-memory `AppRuleStoring` fake for tests that need a `WindowPickerController`.
final class InMemoryAppRuleStore: AppRuleStoring {
  private var rules: [String: AppRule]
  private var storedExclusionPatterns: [AppExclusionPattern]

  init(
    _ rules: [String: AppRule] = [:],
    exclusionPatterns: [AppExclusionPattern] = []
  ) {
    self.rules = rules
    storedExclusionPatterns = exclusionPatterns
  }

  func rule(for bundleIdentifier: String) -> AppRule {
    if let rule = rules[bundleIdentifier] {
      return rule
    }
    return storedExclusionPatterns.contains { $0.matches(bundleIdentifier) }
      ? .excluded
      : .included
  }

  func setRule(_ rule: AppRule, for bundleIdentifier: String) {
    rules[bundleIdentifier] = rule
  }

  func removeRule(for bundleIdentifier: String) {
    rules.removeValue(forKey: bundleIdentifier)
  }

  func exclusionPatterns() -> [AppExclusionPattern] {
    storedExclusionPatterns
  }

  func addExclusionPattern(_ pattern: AppExclusionPattern) {
    guard !storedExclusionPatterns.contains(where: { $0.pattern == pattern.pattern }) else {
      return
    }
    storedExclusionPatterns.append(pattern)
  }

  func updateExclusionPattern(_ pattern: AppExclusionPattern) {
    guard let index = storedExclusionPatterns.firstIndex(where: { $0.id == pattern.id }) else {
      return
    }
    storedExclusionPatterns[index] = pattern
  }

  func removeExclusionPattern(id: UUID) {
    storedExclusionPatterns.removeAll { $0.id == id }
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
