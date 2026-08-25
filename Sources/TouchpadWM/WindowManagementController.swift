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

final class WindowManagementController: WindowManaging, SwitcherWindowManaging {
  private let service: any AccessibilityWindowServicing
  private var catalogue = WindowCatalogue()

  init(service: any AccessibilityWindowServicing) {
    self.service = service
  }

  func apply(_ zone: LayoutZone) -> LayoutOperationResult {
    catalogue.replaceWindows(service.refreshWindows())
    guard let focusedID = service.focusedWindowID(),
      let focusedWindow = catalogue.managedWindows.first(where: { $0.id == focusedID })
    else {
      return .noFocusedManagedWindow
    }

    let frame = LayoutGeometry.frame(for: zone, in: focusedWindow.visibleFrame)
    return service.apply(frame, to: focusedID) ? .applied : .inaccessibleWindow
  }

  func refreshedWindowsForSwitcher() -> [CataloguedWindow] {
    catalogue.replaceWindows(service.refreshWindows())
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
}
