import XCTest

@testable import TouchpadWM

final class AppRuleStoreTests: XCTestCase {
  func testMissingRuleDefaultsToPickerInclusion() {
    let defaults = makeDefaults()
    let store = UserDefaultsAppRuleStore(defaults: defaults)

    XCTAssertEqual(store.rule(for: "com.example.editor"), .included)
  }

  func testRulePersistsAcrossStoreInstances() {
    let defaults = makeDefaults()
    let first = UserDefaultsAppRuleStore(defaults: defaults)
    first.setRule(.init(includeInSwitcher: false), for: "com.example.editor")

    let second = UserDefaultsAppRuleStore(defaults: defaults)
    XCTAssertEqual(second.rule(for: "com.example.editor"), .init(includeInSwitcher: false))
  }

  func testLegacyTwoFieldPayloadDecodesAsPickerRule() throws {
    let defaults = makeDefaults()
    let payload = """
      {"com.example.editor":{"includeInSwitcher":false,"manageLayout":true}}
      """.data(using: .utf8)!
    defaults.set(payload, forKey: "appRules")
    let store = UserDefaultsAppRuleStore(defaults: defaults)

    XCTAssertEqual(store.rule(for: "com.example.editor"), .init(includeInSwitcher: false))
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
