import Foundation
import XCTest

@testable import TouchpadWM

final class AppRulesControllerTests: XCTestCase {
  @MainActor
  func testRefreshExposesInstalledApplicationsAndSearchIsCaseInsensitive() {
    let alpha = InstalledApplication(
      bundleIdentifier: "alpha", name: "Alpha", url: URL(filePath: "/Applications/Alpha.app"))
    let zulu = InstalledApplication(
      bundleIdentifier: "zulu", name: "Zulu", url: URL(filePath: "/Applications/Zulu.app"))
    let controller = AppRulesController(
      inventory: FixedInventory([zulu, alpha]), windowManagement: FakeAppRuleManager())

    controller.refresh()

    XCTAssertEqual(controller.applications.map(\.name), ["Zulu", "Alpha"])
    XCTAssertEqual(controller.applications(matching: "LP").map(\.bundleIdentifier), ["alpha"])
  }

  @MainActor
  func testSettingARuleDelegatesTheIndependentFlagsToWindowManagement() {
    let manager = FakeAppRuleManager()
    let controller = AppRulesController(inventory: FixedInventory([]), windowManagement: manager)
    let rule = AppRule(includeInSwitcher: false, manageLayout: true)

    controller.setRule(rule, for: "com.example.editor")

    XCTAssertEqual(manager.rules["com.example.editor"], rule)
  }
}

private struct FixedInventory: ApplicationInventorying {
  let applications: [InstalledApplication]

  init(_ applications: [InstalledApplication]) {
    self.applications = applications
  }

  func installedApplications() -> [InstalledApplication] {
    applications
  }
}

private final class FakeAppRuleManager: AppRuleManaging {
  private(set) var rules: [String: AppRule] = [:]

  func rule(for bundleIdentifier: String) -> AppRule {
    rules[bundleIdentifier] ?? .included
  }

  func setRule(_ rule: AppRule, for bundleIdentifier: String) {
    rules[bundleIdentifier] = rule
  }
}
