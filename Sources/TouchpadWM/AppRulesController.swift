import Foundation
import Observation

@MainActor
@Observable
final class AppRulesController {
  private let inventory: any ApplicationInventorying
  private let windowPicker: any AppRuleManaging
  private(set) var applications: [InstalledApplication] = []
  private(set) var exclusionPatterns: [AppExclusionPattern] = []
  private var rules: [String: AppRule] = [:]

  init(
    inventory: any ApplicationInventorying = ApplicationInventory(),
    windowPicker: any AppRuleManaging
  ) {
    self.inventory = inventory
    self.windowPicker = windowPicker
  }

  func refresh() {
    applications = inventory.installedApplications()
    exclusionPatterns = windowPicker.exclusionPatterns()
  }

  func applications(matching query: String) -> [InstalledApplication] {
    guard !query.isEmpty else {
      return applications
    }
    return applications.filter {
      $0.name.localizedCaseInsensitiveContains(query)
        || $0.bundleIdentifier.localizedCaseInsensitiveContains(query)
    }
  }

  func rule(for bundleIdentifier: String) -> AppRule {
    rules[bundleIdentifier] ?? windowPicker.rule(for: bundleIdentifier)
  }

  func setRule(_ rule: AppRule, for bundleIdentifier: String) {
    rules[bundleIdentifier] = rule
    windowPicker.setRule(rule, for: bundleIdentifier)
  }

  @discardableResult
  func addExclusionPattern(_ pattern: String) -> Bool {
    let normalizedPattern = pattern.trimmingCharacters(in: .whitespacesAndNewlines)
    guard
      let exclusionPattern = AppExclusionPattern(pattern: normalizedPattern),
      !exclusionPatterns.contains(where: { $0.pattern == exclusionPattern.pattern })
    else {
      return false
    }

    exclusionPatterns.append(exclusionPattern)
    windowPicker.addExclusionPattern(exclusionPattern)
    return true
  }

  func removeExclusionPattern(_ pattern: AppExclusionPattern) {
    guard exclusionPatterns.contains(where: { $0.id == pattern.id }) else {
      return
    }

    exclusionPatterns.removeAll { $0.id == pattern.id }
    windowPicker.removeExclusionPattern(id: pattern.id)
  }
}
