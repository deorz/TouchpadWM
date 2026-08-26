import CoreGraphics

enum LayoutOperationResult: Equatable {
  case applied
  case noFocusedManagedWindow
  case inaccessibleWindow
}

protocol AccessibilityWindowServicing: AnyObject {
  func refreshWindows() -> [CataloguedWindow]
  func focusedWindowID() -> WindowID?
  func apply(_ frame: CGRect, to id: WindowID) -> Bool
  func activate(_ id: WindowID) -> Bool
}

protocol WindowManaging: AnyObject {
  func apply(_ zone: LayoutZone) -> LayoutOperationResult
}

protocol SwitcherWindowManaging: AnyObject {
  func refreshedWindowsForSwitcher() -> [CataloguedWindow]
  func markWindowFocused(_ id: WindowID)
  func activate(_ id: WindowID) -> Bool
}

protocol AppRuleManaging: AnyObject {
  func rule(for bundleIdentifier: String) -> AppRule
  func setRule(_ rule: AppRule, for bundleIdentifier: String)
}

final class WindowManagementController: WindowManaging, SwitcherWindowManaging, AppRuleManaging {
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

  func apply(_ zone: LayoutZone) -> LayoutOperationResult {
    refreshCatalogue()
    guard let focusedID = service.focusedWindowID(),
      let focusedWindow = catalogue.managedWindows.first(where: { $0.id == focusedID })
    else {
      return .noFocusedManagedWindow
    }

    let frame = LayoutGeometry.frame(for: zone, in: focusedWindow.visibleFrame)
    return service.apply(frame, to: focusedID) ? .applied : .inaccessibleWindow
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

  private func refreshCatalogue() {
    let windows = service.refreshWindows()
    catalogue.replaceWindows(windows)
    for bundleIdentifier in Set(windows.map(\.bundleIdentifier)) {
      catalogue.setRule(ruleStore.rule(for: bundleIdentifier), for: bundleIdentifier)
    }
  }
}
