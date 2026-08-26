import Foundation
import Observation
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
      inventory: FixedInventory([zulu, alpha]), windowPicker: FakeAppRuleManager())

    controller.refresh()

    XCTAssertEqual(controller.applications.map(\.name), ["Zulu", "Alpha"])
    XCTAssertEqual(controller.applications(matching: "LP").map(\.bundleIdentifier), ["alpha"])
  }

  @MainActor
  func testSettingARuleInvalidatesAnObservedRule() {
    let controller = AppRulesController(
      inventory: FixedInventory([]), windowPicker: FakeAppRuleManager())
    let observation = ObservationChangeRecorder()

    withObservationTracking {
      _ = controller.rule(for: "com.example.editor")
    } onChange: {
      observation.recordChange()
    }

    controller.setRule(.excluded, for: "com.example.editor")

    XCTAssertTrue(observation.didObserveChange)
  }

  @MainActor
  func testSettingARuleDelegatesPickerInclusionToWindowPicker() {
    let manager = FakeAppRuleManager()
    let controller = AppRulesController(inventory: FixedInventory([]), windowPicker: manager)
    let rule = AppRule(includeInSwitcher: false)

    controller.setRule(rule, for: "com.example.editor")

    XCTAssertEqual(manager.rules["com.example.editor"], rule)
  }
}

private final class ObservationChangeRecorder: @unchecked Sendable {
  private let lock = NSLock()
  private var changed = false

  var didObserveChange: Bool {
    lock.withLock { changed }
  }

  func recordChange() {
    lock.withLock { changed = true }
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
