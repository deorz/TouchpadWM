import CoreGraphics
import Foundation
import XCTest

@testable import TouchpadWM

final class CustomAppExclusionsTests: XCTestCase {
  func testValidBundleIdentifierPatternMatchesCaseInsensitively() throws {
    let pattern = try XCTUnwrap(AppExclusionPattern(pattern: #"^com\.checkpoint\."#))

    XCTAssertTrue(pattern.matches("com.checkpoint.EPWebGUI"))
    XCTAssertTrue(pattern.matches("COM.CHECKPOINT.da.app"))
    XCTAssertFalse(pattern.matches("com.example.editor"))
  }

  func testEmptyAndInvalidPatternsAreRejected() {
    XCTAssertNil(AppExclusionPattern(pattern: ""))
    XCTAssertNil(AppExclusionPattern(pattern: "["))
  }

  func testCustomExclusionPersistsAndAppliesToMatchingBundleIdentifiers() throws {
    let defaults = makeDefaults()
    let firstStore = UserDefaultsAppRuleStore(defaults: defaults)
    let pattern = try XCTUnwrap(AppExclusionPattern(pattern: #"^com\.checkpoint\."#))

    firstStore.addExclusionPattern(pattern)

    let secondStore = UserDefaultsAppRuleStore(defaults: defaults)

    XCTAssertEqual(secondStore.exclusionPatterns(), [pattern])
    XCTAssertEqual(secondStore.rule(for: "com.checkpoint.EPWebGUI"), .excluded)
    XCTAssertEqual(secondStore.rule(for: "com.example.editor"), .included)
  }

  func testExactApplicationRuleOverridesMatchingCustomExclusion() throws {
    let defaults = makeDefaults()
    let store = UserDefaultsAppRuleStore(defaults: defaults)
    let pattern = try XCTUnwrap(AppExclusionPattern(pattern: #"^com\.checkpoint\."#))

    store.addExclusionPattern(pattern)
    store.setRule(.included, for: "com.checkpoint.EPWebGUI")

    XCTAssertEqual(store.rule(for: "com.checkpoint.EPWebGUI"), .included)
  }

  func testRemovingCustomExclusionStopsMatchingBundleIdentifiersFromBeingExcluded() throws {
    let defaults = makeDefaults()
    let store = UserDefaultsAppRuleStore(defaults: defaults)
    let pattern = try XCTUnwrap(AppExclusionPattern(pattern: #"^com\.checkpoint\."#))

    store.addExclusionPattern(pattern)
    store.removeExclusionPattern(id: pattern.id)

    XCTAssertEqual(store.exclusionPatterns(), [])
    XCTAssertEqual(store.rule(for: "com.checkpoint.EPWebGUI"), .included)
  }

  func testWindowPickerAppliesCustomExclusionToRuntimeWindowOwner() throws {
    let defaults = makeDefaults()
    let store = UserDefaultsAppRuleStore(defaults: defaults)
    let pattern = try XCTUnwrap(AppExclusionPattern(pattern: #"^com\.checkpoint\."#))
    store.addExclusionPattern(pattern)

    let excludedWindow = makeWindow(
      id: 1,
      bundleIdentifier: "com.checkpoint.EPWebGUI",
      applicationName: "Endpoint Security")
    let includedWindow = makeWindow(
      id: 2,
      bundleIdentifier: "com.example.editor",
      applicationName: "Editor")
    let controller = WindowPickerController(
      service: FixedWindowService(windows: [excludedWindow, includedWindow]),
      ruleStore: store)

    XCTAssertEqual(
      controller.refreshedWindowsForSwitcher().map(\.bundleIdentifier),
      ["com.example.editor"])
  }

  @MainActor
  func testControllerLoadsAddsAndRemovesCustomExclusions() throws {
    let initialPattern = try XCTUnwrap(AppExclusionPattern(pattern: #"^com\.checkpoint\."#))
    let manager = RecordingAppRuleManager(patterns: [initialPattern])
    let controller = AppRulesController(
      inventory: EmptyInventory(),
      windowPicker: manager)

    controller.refresh()

    XCTAssertEqual(controller.exclusionPatterns, [initialPattern])
    XCTAssertTrue(controller.addExclusionPattern(#"^com\.example\."#))
    XCTAssertFalse(controller.addExclusionPattern(#"^com\.example\."#))
    XCTAssertFalse(controller.addExclusionPattern("["))
    XCTAssertEqual(manager.exclusionPatterns.count, 2)

    controller.removeExclusionPattern(initialPattern)

    XCTAssertEqual(controller.exclusionPatterns.count, 1)
    XCTAssertEqual(manager.exclusionPatterns.count, 1)
    XCTAssertEqual(manager.exclusionPatterns.first?.pattern, #"^com\.example\."#)
  }

  private func makeWindow(
    id: CGWindowID,
    bundleIdentifier: String,
    applicationName: String
  ) -> CataloguedWindow {
    CataloguedWindow(
      id: WindowID(processIdentifier: 1, windowNumber: id),
      bundleIdentifier: bundleIdentifier,
      applicationName: applicationName,
      title: "Window \(id)",
      role: .normal,
      isMinimized: false,
      visibleFrame: CGRect(x: 0, y: 0, width: 1000, height: 800))
  }

  private func makeDefaults() -> UserDefaults {
    let name = "CustomAppExclusionsTests.\(UUID().uuidString)"
    let defaults = UserDefaults(suiteName: name)!
    addTeardownBlock {
      defaults.removePersistentDomain(forName: name)
    }
    return defaults
  }
}

private struct EmptyInventory: ApplicationInventorying {
  func installedApplications() -> [InstalledApplication] {
    []
  }
}

private final class RecordingAppRuleManager: AppRuleManaging {
  private(set) var rules: [String: AppRule] = [:]
  private(set) var exclusionPatterns: [AppExclusionPattern]

  init(patterns: [AppExclusionPattern] = []) {
    exclusionPatterns = patterns
  }

  func rule(for bundleIdentifier: String) -> AppRule {
    if let rule = rules[bundleIdentifier] {
      return rule
    }
    return exclusionPatterns.contains(where: { $0.matches(bundleIdentifier) })
      ? .excluded
      : .included
  }

  func setRule(_ rule: AppRule, for bundleIdentifier: String) {
    rules[bundleIdentifier] = rule
  }

  func exclusionPatterns() -> [AppExclusionPattern] {
    exclusionPatterns
  }

  func addExclusionPattern(_ pattern: AppExclusionPattern) {
    exclusionPatterns.append(pattern)
  }

  func removeExclusionPattern(id: UUID) {
    exclusionPatterns.removeAll { $0.id == id }
  }
}

private final class FixedWindowService: AccessibilityWindowServicing {
  let windows: [CataloguedWindow]

  init(windows: [CataloguedWindow]) {
    self.windows = windows
  }

  func refreshWindows() -> [CataloguedWindow] {
    windows
  }

  func focusedWindowID() -> WindowID? {
    windows.first?.id
  }

  func activate(_ id: WindowID) -> Bool {
    windows.contains { $0.id == id }
  }
}
