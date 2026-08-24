import AppKit
import ApplicationServices
import Foundation
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
    guard
      let url = URL(
        string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility")
    else {
      return false
    }
    return NSWorkspace.shared.open(url)
  }
}

@MainActor
@Observable
final class AppState {
  private(set) var accessibilityPermission: AccessibilityPermissionState
  private(set) var windowManagementStatus = ""
  private let permissionChecker: any AccessibilityPermissionChecking
  private let windowManagement: any WindowManaging
  private var permissionRefreshTimer: Timer?

  init(
    permissionChecker: any AccessibilityPermissionChecking = AccessibilityPermissionService(),
    windowManagement: any WindowManaging = WindowManagementController(
      service: AccessibilityWindowService())
  ) {
    self.permissionChecker = permissionChecker
    self.windowManagement = windowManagement
    accessibilityPermission = permissionChecker.isTrusted() ? .available : .unavailable
    permissionRefreshTimer = Timer.scheduledTimer(withTimeInterval: 2, repeats: true) {
      [weak self] _ in
      Task { @MainActor in
        self?.refreshAccessibilityPermission()
      }
    }
  }

  func refreshAccessibilityPermission() {
    accessibilityPermission = permissionChecker.isTrusted() ? .available : .unavailable
  }

  func openAccessibilitySettings() {
    _ = permissionChecker.openSettings()
  }

  func performLayoutCommand(_ command: LayoutCommand) {
    guard accessibilityPermission == .available else {
      windowManagementStatus = "Accessibility access is required."
      return
    }

    switch windowManagement.apply(command.zone) {
    case .applied:
      windowManagementStatus = "Applied \(command.description) layout."
    case .noFocusedManagedWindow:
      windowManagementStatus = "No managed focused window."
    case .inaccessibleWindow:
      windowManagementStatus = "The focused window is not accessible."
    }
  }
}

private extension LayoutCommand {
  var description: String {
    switch self {
    case .leftHalf: "left half"
    case .rightHalf: "right half"
    case .leftThreeQuarters: "left 75%"
    case .rightQuarter: "right 25%"
    case .topRightQuarter: "top-right 25%"
    case .bottomRightQuarter: "bottom-right 25%"
    case .masterStack: "master stack"
    }
  }
}
