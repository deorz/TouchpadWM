import Foundation
import Observation

@Observable
final class ApplicationPreferences {
  private static let menuBarIconKey = "showMenuBarIcon"
  private let defaults: UserDefaults

  init(defaults: UserDefaults = .standard) {
    self.defaults = defaults
    showMenuBarIcon = defaults.object(forKey: Self.menuBarIconKey) as? Bool ?? true
  }

  var showMenuBarIcon: Bool {
    didSet {
      defaults.set(showMenuBarIcon, forKey: Self.menuBarIconKey)
    }
  }
}
