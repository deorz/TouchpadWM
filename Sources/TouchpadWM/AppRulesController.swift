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
    rules.removeAll()
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

  func setApplicationIncluded(_ included: Bool, for bundleIdentifier: String) {
    rules.removeValue(forKey: bundleIdentifier)
    windowPicker.removeRule(for: bundleIdentifier)

    if included {
      let applicationPatterns = exclusionPatterns.filter {
        $0.sourceBundleIdentifier == bundleIdentifier
      }
      applicationPatterns.forEach(removeExclusionPattern)

      if !windowPicker.rule(for: bundleIdentifier).includeInSwitcher {
        setRule(.included, for: bundleIdentifier)
      }
      return
    }

    guard
      !exclusionPatterns.contains(where: {
        $0.sourceBundleIdentifier == bundleIdentifier
      }),
      let pattern = AppExclusionPattern(exactBundleIdentifier: bundleIdentifier)
    else {
      return
    }

    addExclusionPattern(pattern)
  }

  @discardableResult
  func addExclusionPattern(_ pattern: String) -> Bool {
    let normalizedPattern = pattern.trimmingCharacters(in: .whitespacesAndNewlines)
    guard let exclusionPattern = AppExclusionPattern(pattern: normalizedPattern) else {
      return false
    }

    return addExclusionPattern(exclusionPattern)
  }

  @discardableResult
  private func addExclusionPattern(_ pattern: AppExclusionPattern) -> Bool {
    guard
      pattern.isValid,
      !exclusionPatterns.contains(where: { $0.pattern == pattern.pattern })
    else {
      return false
    }

    exclusionPatterns.append(pattern)
    windowPicker.addExclusionPattern(pattern)
    return true
  }

  @discardableResult
  func updateExclusionPattern(
    _ pattern: AppExclusionPattern,
    to newPattern: String
  ) -> Bool {
    let normalizedPattern = newPattern.trimmingCharacters(in: .whitespacesAndNewlines)
    guard let index = exclusionPatterns.firstIndex(where: { $0.id == pattern.id }) else {
      return false
    }

    let currentPattern = exclusionPatterns[index]
    guard
      let updatedPattern = AppExclusionPattern(
        id: currentPattern.id,
        pattern: normalizedPattern,
        sourceBundleIdentifier: currentPattern.sourceBundleIdentifier),
      !exclusionPatterns.contains(where: {
        $0.id != currentPattern.id && $0.pattern == updatedPattern.pattern
      })
    else {
      return false
    }

    exclusionPatterns[index] = updatedPattern
    windowPicker.updateExclusionPattern(updatedPattern)
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
