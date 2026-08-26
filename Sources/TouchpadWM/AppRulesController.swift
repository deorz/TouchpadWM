import Observation

@MainActor
@Observable
final class AppRulesController {
  private let inventory: any ApplicationInventorying
  private let windowManagement: any AppRuleManaging
  private(set) var applications: [InstalledApplication] = []
  private var rules: [String: AppRule] = [:]

  init(
    inventory: any ApplicationInventorying = ApplicationInventory(),
    windowManagement: any AppRuleManaging
  ) {
    self.inventory = inventory
    self.windowManagement = windowManagement
  }

  func refresh() {
    applications = inventory.installedApplications()
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
    rules[bundleIdentifier] ?? windowManagement.rule(for: bundleIdentifier)
  }

  func setRule(_ rule: AppRule, for bundleIdentifier: String) {
    rules[bundleIdentifier] = rule
    windowManagement.setRule(rule, for: bundleIdentifier)
  }
}
