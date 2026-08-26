import Foundation

protocol AppRuleStoring: AnyObject {
  func rule(for bundleIdentifier: String) -> AppRule
  func setRule(_ rule: AppRule, for bundleIdentifier: String)
}

final class UserDefaultsAppRuleStore: AppRuleStoring {
  private let defaults: UserDefaults
  private let key: String

  init(defaults: UserDefaults = .standard, key: String = "appRules") {
    self.defaults = defaults
    self.key = key
  }

  func rule(for bundleIdentifier: String) -> AppRule {
    rules[bundleIdentifier] ?? .included
  }

  func setRule(_ rule: AppRule, for bundleIdentifier: String) {
    var updated = rules
    updated[bundleIdentifier] = rule
    defaults.set(try? JSONEncoder().encode(updated), forKey: key)
  }

  private var rules: [String: AppRule] {
    guard let data = defaults.data(forKey: key),
      let rules = try? JSONDecoder().decode([String: AppRule].self, from: data)
    else { return [:] }
    return rules
  }
}
