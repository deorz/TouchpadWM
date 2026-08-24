import AppKit
import ApplicationServices
import Observation

enum AccessibilityPermissionState: Equatable {
  case available
  case unavailable
}

protocol AccessibilityPermissionChecking {
  func isTrusted() -> Bool
  func openSettings() -> Bool
}

struct AccessibilityPermissionService: AccessibilityPermissionChecking {
  func isTrusted() -> Bool {
    AXIsProcessTrusted()
  }

  func openSettings() -> Bool {
    guard let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility") else {
      return false
    }
    return NSWorkspace.shared.open(url)
  }
}

@MainActor
@Observable
final class AppState {
  private(set) var accessibilityPermission: AccessibilityPermissionState
  private let permissionChecker: any AccessibilityPermissionChecking

  init(permissionChecker: any AccessibilityPermissionChecking = AccessibilityPermissionService()) {
    self.permissionChecker = permissionChecker
    accessibilityPermission = permissionChecker.isTrusted() ? .available : .unavailable
  }

  func refreshAccessibilityPermission() {
    accessibilityPermission = permissionChecker.isTrusted() ? .available : .unavailable
  }

  func openAccessibilitySettings() {
    _ = permissionChecker.openSettings()
  }
}
