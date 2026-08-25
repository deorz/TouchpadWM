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

final class WindowManagementController: WindowManaging {
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
}
