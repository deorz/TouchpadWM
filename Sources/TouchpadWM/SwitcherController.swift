struct SwitcherSession: Equatable {
  let windows: [CataloguedWindow]
  var selectedIndex: Int

  var selectedWindow: CataloguedWindow? {
    windows.indices.contains(selectedIndex) ? windows[selectedIndex] : nil
  }
}

/// Owns one switcher session at a time. `windows[0]` is the most-recently-used window (the
/// spec's "bottom" row); moving `.previous` steps toward older windows, `.next` steps back
/// toward the current one. Selection is clamped, not cyclic, matching "the overlay scrolls
/// when needed" in the V1 design.
final class SwitcherController {
  private(set) var session: SwitcherSession?
  private let windowSource: any SwitcherWindowSourcing

  init(windowSource: any SwitcherWindowSourcing) {
    self.windowSource = windowSource
  }

  func open() {
    let windows = windowSource.refreshedWindowsForSwitcher()
    session = windows.isEmpty ? nil : SwitcherSession(windows: windows, selectedIndex: 0)
  }

  func moveSelection(_ direction: SwitcherDirection) {
    guard var session else {
      return
    }
    switch direction {
    case .previous:
      session.selectedIndex = min(session.selectedIndex + 1, session.windows.count - 1)
    case .next:
      session.selectedIndex = max(session.selectedIndex - 1, 0)
    }
    self.session = session
  }

  @discardableResult
  func activateSelection() -> Bool {
    defer { session = nil }
    guard let selected = session?.selectedWindow else {
      return false
    }
    guard windowSource.activate(selected.id) else {
      return false
    }
    windowSource.markWindowFocused(selected.id)
    return true
  }

  func cancel() {
    session = nil
  }
}
