import XCTest

@testable import TouchpadWM

final class ApplicationPreferencesTests: XCTestCase {
  func testMenuBarIconIsVisibleWithoutASavedPreference() {
    XCTAssertTrue(ApplicationPreferences(defaults: makeDefaults()).showMenuBarIcon)
  }

  func testMenuBarVisibilityPersistsInBothDirectionsWithoutChangingGesturePreferences() {
    let defaults = makeDefaults()
    let gestures = GesturePreferences(defaults: defaults)
    gestures.pickerFingerCount = .five
    let preferences = ApplicationPreferences(defaults: defaults)

    preferences.showMenuBarIcon = false
    XCTAssertFalse(ApplicationPreferences(defaults: defaults).showMenuBarIcon)
    preferences.showMenuBarIcon = true
    XCTAssertTrue(ApplicationPreferences(defaults: defaults).showMenuBarIcon)
    XCTAssertEqual(GesturePreferences(defaults: defaults).pickerFingerCount, .five)
  }

  func testInvalidSavedVisibilityKeepsTheMenuBarAccessible() {
    let defaults = makeDefaults()
    defaults.set("invalid", forKey: "showMenuBarIcon")

    XCTAssertTrue(ApplicationPreferences(defaults: defaults).showMenuBarIcon)
  }

  private func makeDefaults() -> UserDefaults {
    let name = "ApplicationPreferencesTests.\(UUID().uuidString)"
    let defaults = UserDefaults(suiteName: name)!
    addTeardownBlock {
      UserDefaults(suiteName: name)?.removePersistentDomain(forName: name)
    }
    return defaults
  }
}
