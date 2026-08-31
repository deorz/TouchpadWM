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

  func testEditingCustomExclusionPersistsWithTheSameIdentity() throws {
    let defaults = makeDefaults()
    let firstStore = UserDefaultsAppRuleStore(defaults: defaults)
    let initialPattern = try XCTUnwrap(
      AppExclusionPattern(pattern: #"^com\.checkpoint\."#))
    firstStore.addExclusionPattern(initialPattern)

    let updatedPattern = try XCTUnwrap(
      AppExclusionPattern(
        id: initialPattern.id,
        pattern: #"^com\.checkpoint\..*$"#,
        sourceBundleIdentifier: initialPattern.sourceBundleIdentifier))
    firstStore.updateExclusionPattern(updatedPattern)

    let secondStore = UserDefaultsAppRuleStore(defaults: defaults)

    XCTAssertEqual(secondStore.exclusionPatterns(), [updatedPattern])
    XCTAssertEqual(
      secondStore.rule(for: "com.checkpoint.EPWebGUI"),
      .excluded)
  }

  func testRemovingAnExactRuleRestoresPatternEvaluation() throws {
    let defaults = makeDefaults()
    let store = UserDefaultsAppRuleStore(defaults: defaults)
    let applicationID = "com.example.editor"

    store.setRule(.excluded, for: applicationID)
    XCTAssertEqual(store.rule(for: applicationID), .excluded)

    store.removeRule(for: applicationID)

    XCTAssertEqual(store.rule(for: applicationID), .included)
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

  func testWindowPickerExposesCustomExclusionManagement() throws {
    let defaults = makeDefaults()
    let store = UserDefaultsAppRuleStore(defaults: defaults)
    let controller = WindowPickerController(
      service: FixedWindowService(windows: []),
      ruleStore: store)
    let pattern = try XCTUnwrap(AppExclusionPattern(pattern: #"^com\.checkpoint\."#))

    controller.addExclusionPattern(pattern)
    XCTAssertEqual(controller.exclusionPatterns(), [pattern])

    controller.removeExclusionPattern(id: pattern.id)
    XCTAssertEqual(controller.exclusionPatterns(), [])
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
    XCTAssertEqual(manager.storedPatterns.count, 2)

    controller.removeExclusionPattern(initialPattern)

    XCTAssertEqual(controller.exclusionPatterns.count, 1)
    XCTAssertEqual(manager.storedPatterns.count, 1)
    XCTAssertEqual(manager.storedPatterns.first?.pattern, #"^com\.example\."#)
  }

  @MainActor
  func testDisablingApplicationAddsAnExactEditableExclusion() throws {
    let application = InstalledApplication(
      bundleIdentifier: "com.checkpoint.EPWebGUI",
      name: "Endpoint Security",
      url: URL(filePath: "/Applications/Endpoint Security.app"))
    let manager = RecordingAppRuleManager()
    let controller = AppRulesController(
      inventory: EmptyInventory(),
      windowPicker: manager)

    controller.refresh()
    controller.setApplicationIncluded(false, for: application.bundleIdentifier)

    let generatedPattern = try XCTUnwrap(controller.exclusionPatterns.first)
    XCTAssertEqual(generatedPattern.pattern, #"^com\.checkpoint\.EPWebGUI$"#)
    XCTAssertEqual(generatedPattern.sourceBundleIdentifier, application.bundleIdentifier)
    XCTAssertEqual(controller.rule(for: application.bundleIdentifier), .excluded)

    XCTAssertTrue(
      controller.updateExclusionPattern(
        generatedPattern,
        to: #"^com\.checkpoint\."#))
    XCTAssertEqual(controller.exclusionPatterns.first?.pattern, #"^com\.checkpoint\."#)
    XCTAssertEqual(controller.rule(for: "com.checkpoint.da.app"), .excluded)
  }

  @MainActor
  func testEnablingApplicationRemovesItsGeneratedExclusion() throws {
    let application = InstalledApplication(
      bundleIdentifier: "com.example.editor",
      name: "Editor",
      url: URL(filePath: "/Applications/Editor.app"))
    let manager = RecordingAppRuleManager()
    let controller = AppRulesController(
      inventory: EmptyInventory(),
      windowPicker: manager)

    controller.refresh()
    controller.setApplicationIncluded(false, for: application.bundleIdentifier)
    controller.setApplicationIncluded(true, for: application.bundleIdentifier)

    XCTAssertTrue(controller.exclusionPatterns.isEmpty)
    XCTAssertEqual(controller.rule(for: application.bundleIdentifier), .included)
  }

  @MainActor
  func testInvalidExclusionEditLeavesTheExistingPatternUntouched() throws {
    let initialPattern = try XCTUnwrap(
      AppExclusionPattern(pattern: #"^com\.checkpoint\."#))
    let manager = RecordingAppRuleManager(patterns: [initialPattern])
    let controller = AppRulesController(
      inventory: EmptyInventory(),
      windowPicker: manager)

    controller.refresh()

    XCTAssertFalse(controller.updateExclusionPattern(initialPattern, to: "["))
    XCTAssertEqual(controller.exclusionPatterns, [initialPattern])
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
  private(set) var storedPatterns: [AppExclusionPattern]

  init(patterns: [AppExclusionPattern] = []) {
    storedPatterns = patterns
  }

  func rule(for bundleIdentifier: String) -> AppRule {
    if let rule = rules[bundleIdentifier] {
      return rule
    }
    return storedPatterns.contains(where: { $0.matches(bundleIdentifier) })
      ? .excluded
      : .included
  }

  func setRule(_ rule: AppRule, for bundleIdentifier: String) {
    rules[bundleIdentifier] = rule
  }

  func removeRule(for bundleIdentifier: String) {
    rules.removeValue(forKey: bundleIdentifier)
  }

  func exclusionPatterns() -> [AppExclusionPattern] {
    storedPatterns
  }

  func addExclusionPattern(_ pattern: AppExclusionPattern) {
    storedPatterns.append(pattern)
  }

  func updateExclusionPattern(_ pattern: AppExclusionPattern) {
    guard let index = storedPatterns.firstIndex(where: { $0.id == pattern.id }) else {
      return
    }
    storedPatterns[index] = pattern
  }

  func removeExclusionPattern(id: UUID) {
    storedPatterns.removeAll { $0.id == id }
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
