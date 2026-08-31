import Foundation

protocol AppRuleStoring: AnyObject {
  func rule(for bundleIdentifier: String) -> AppRule
  func setRule(_ rule: AppRule, for bundleIdentifier: String)
  func exclusionPatterns() -> [AppExclusionPattern]
  func addExclusionPattern(_ pattern: AppExclusionPattern)
  func removeExclusionPattern(id: UUID)
}

final class UserDefaultsAppRuleStore: AppRuleStoring {
  private let defaults: UserDefaults
  private let key: String

  private var patternsKey: String {
    "\(key).exclusionPatterns"
  }

  init(defaults: UserDefaults = .standard, key: String = "appRules") {
    self.defaults = defaults
    self.key = key
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
    var updated = rules
    updated[bundleIdentifier] = rule
    defaults.set(try? JSONEncoder().encode(updated), forKey: key)
  }

  func exclusionPatterns() -> [AppExclusionPattern] {
    storedExclusionPatterns
  }

  func addExclusionPattern(_ pattern: AppExclusionPattern) {
    guard
      pattern.isValid,
      !storedExclusionPatterns.contains(where: { $0.pattern == pattern.pattern })
    else {
      return
    }

    saveExclusionPatterns(storedExclusionPatterns + [pattern])
  }

  func removeExclusionPattern(id: UUID) {
    saveExclusionPatterns(storedExclusionPatterns.filter { $0.id != id })
  }

  private var rules: [String: AppRule] {
    guard let data = defaults.data(forKey: key),
      let rules = try? JSONDecoder().decode([String: AppRule].self, from: data)
    else { return [:] }
    return rules
  }

  private var storedExclusionPatterns: [AppExclusionPattern] {
    guard
      let data = defaults.data(forKey: patternsKey),
      let patterns = try? JSONDecoder().decode([AppExclusionPattern].self, from: data)
    else {
      return []
    }
    return patterns.filter(\.isValid)
  }

  private func saveExclusionPatterns(_ patterns: [AppExclusionPattern]) {
    defaults.set(try? JSONEncoder().encode(patterns), forKey: patternsKey)
  }
}
