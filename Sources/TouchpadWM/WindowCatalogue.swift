import CoreGraphics
import Foundation

struct WindowID: Hashable {
  let processIdentifier: pid_t
  let windowNumber: CGWindowID
}

enum WindowRole: Equatable {
  case normal
  case dialog
  case sheet
  case popover
  case utility
  case floating
  case unknown
}

struct CataloguedWindow: Equatable {
  let id: WindowID
  let bundleIdentifier: String
  let applicationName: String
  let title: String
  let role: WindowRole
  let isMinimized: Bool
  let visibleFrame: CGRect
}

struct AppRule: Codable, Equatable {
  var includeInSwitcher: Bool

  static let included = AppRule(includeInSwitcher: true)
  static let excluded = AppRule(includeInSwitcher: false)
}

struct WindowCatalogue {
  private var windows: [WindowID: CataloguedWindow] = [:]
  private var mru: [WindowID] = []
  private var rules: [String: AppRule] = [:]

  var windowsForSwitcher: [CataloguedWindow] {
    orderedWindows.filter { rule(for: $0).includeInSwitcher }
  }

  mutating func replaceWindows(_ refreshedWindows: [CataloguedWindow]) {
    let refreshedIDs = Set(refreshedWindows.map(\.id))
    windows = Dictionary(uniqueKeysWithValues: refreshedWindows.map { ($0.id, $0) })
    mru.removeAll { !refreshedIDs.contains($0) }
    for window in refreshedWindows where !mru.contains(window.id) {
      mru.append(window.id)
    }
  }

  mutating func setRule(_ rule: AppRule, for bundleIdentifier: String) {
    rules[bundleIdentifier] = rule
  }

  mutating func markFocused(_ id: WindowID) {
    guard windows[id] != nil else {
      return
    }
    mru.removeAll { $0 == id }
    mru.insert(id, at: 0)
  }

  private var orderedWindows: [CataloguedWindow] {
    mru.compactMap { windows[$0] }
  }

  private func rule(for window: CataloguedWindow) -> AppRule {
    if window.bundleIdentifier == "com.apple.finder" {
      return .excluded
    }
    return rules[window.bundleIdentifier] ?? .included
  }
}
