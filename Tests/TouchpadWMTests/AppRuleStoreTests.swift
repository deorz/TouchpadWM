import XCTest

@testable import TouchpadWM

final class AppRuleStoreTests: XCTestCase {
  func testMissingRuleDefaultsToBothFeaturesIncluded() {
    let defaults = makeDefaults()
    let store = UserDefaultsAppRuleStore(defaults: defaults)

    XCTAssertEqual(store.rule(for: "com.example.editor"), .included)
  }

  func testRulePersistsAcrossStoreInstancesAndKeepsFlagsIndependent() {
    let defaults = makeDefaults()
    let first = UserDefaultsAppRuleStore(defaults: defaults)
    first.setRule(
      .init(includeInSwitcher: false, manageLayout: true), for: "com.example.editor")

    let second = UserDefaultsAppRuleStore(defaults: defaults)
    XCTAssertEqual(
      second.rule(for: "com.example.editor"),
      .init(includeInSwitcher: false, manageLayout: true))
  }

  private func makeDefaults() -> UserDefaults {
    let name = "AppRuleStoreTests.\(UUID().uuidString)"
    let defaults = UserDefaults(suiteName: name)!
    addTeardownBlock {
      UserDefaults.standard.removePersistentDomain(forName: name)
    }
    return defaults
  }
}
