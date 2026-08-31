import Foundation

protocol AccessibilityWindowServicing: AnyObject {
  func refreshWindows() -> [CataloguedWindow]
  func focusedWindowID() -> WindowID?
  func activate(_ id: WindowID) -> Bool
}

protocol SwitcherWindowSourcing: AnyObject {
  func refreshedWindowsForSwitcher() -> [CataloguedWindow]
  func markWindowFocused(_ id: WindowID)
  func activate(_ id: WindowID) -> Bool
}

protocol AppRuleManaging: AnyObject {
  func rule(for bundleIdentifier: String) -> AppRule
  func setRule(_ rule: AppRule, for bundleIdentifier: String)
  func exclusionPatterns() -> [AppExclusionPattern]
  func addExclusionPattern(_ pattern: AppExclusionPattern)
  func removeExclusionPattern(id: UUID)
}

final class WindowPickerController: SwitcherWindowSourcing, AppRuleManaging {
  private let service: any AccessibilityWindowServicing
  private let ruleStore: any AppRuleStoring
  private var catalogue = WindowCatalogue()

  init(
    service: any AccessibilityWindowServicing,
    ruleStore: any AppRuleStoring = UserDefaultsAppRuleStore()
  ) {
    self.service = service
    self.ruleStore = ruleStore
  }

  func refreshedWindowsForSwitcher() -> [CataloguedWindow] {
    refreshCatalogue()
    if let focusedID = service.focusedWindowID() {
      catalogue.markFocused(focusedID)
    }
    return catalogue.windowsForSwitcher
  }

  func markWindowFocused(_ id: WindowID) {
    catalogue.markFocused(id)
  }

  func activate(_ id: WindowID) -> Bool {
    service.activate(id)
  }

  func rule(for bundleIdentifier: String) -> AppRule {
    ruleStore.rule(for: bundleIdentifier)
  }

  func setRule(_ rule: AppRule, for bundleIdentifier: String) {
    ruleStore.setRule(rule, for: bundleIdentifier)
  }

  func exclusionPatterns() -> [AppExclusionPattern] {
    ruleStore.exclusionPatterns()
  }

  func addExclusionPattern(_ pattern: AppExclusionPattern) {
    ruleStore.addExclusionPattern(pattern)
  }

  func removeExclusionPattern(id: UUID) {
    ruleStore.removeExclusionPattern(id: id)
  }

  private func refreshCatalogue() {
    let windows = service.refreshWindows()
    catalogue.replaceWindows(windows)
    for bundleIdentifier in Set(windows.map(\.bundleIdentifier)) {
      catalogue.setRule(ruleStore.rule(for: bundleIdentifier), for: bundleIdentifier)
    }
  }
}
