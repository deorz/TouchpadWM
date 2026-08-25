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
  func requestTrust()
}

protocol InputMonitoringPermissionChecking {
  func hasAccess() -> Bool
  func requestAccess() -> Bool
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

  func requestTrust() {
    // Passing the prompt option asks macOS itself to show its own "<App> would like to control
    // this computer" Accessibility alert once, the same alert the system throws up incidentally
    // when an untrusted process tries to create a session-level CGEventTap. isTrusted() above is
    // deliberately left as a passive check (no prompt) so it stays safe to call from polling.
    // kAXTrustedCheckOptionPrompt is imported as a global `var` (no Sendable overlay), which
    // Swift 6 strict concurrency flags as unsafe from any context; its value is the stable,
    // documented string "AXTrustedCheckOptionPrompt", so that literal is used directly instead.
    _ = AXIsProcessTrustedWithOptions(["AXTrustedCheckOptionPrompt": true] as CFDictionary)
  }
}

struct InputMonitoringPermissionService: InputMonitoringPermissionChecking {
  func hasAccess() -> Bool {
    CGPreflightListenEventAccess()
  }

  func requestAccess() -> Bool {
    CGRequestListenEventAccess()
  }
}

@MainActor
@Observable
final class AppState {
  private(set) var accessibilityPermission: AccessibilityPermissionState
  private(set) var inputMonitoringPermission: AccessibilityPermissionState
  private(set) var windowManagementStatus = ""
  private let permissionChecker: any AccessibilityPermissionChecking
  private let inputMonitoringChecker: any InputMonitoringPermissionChecking
  private let windowManagement: any WindowManaging
  private let refreshInterval: TimeInterval
  private var permissionRefreshTimer: Timer?

  init(
    permissionChecker: any AccessibilityPermissionChecking = AccessibilityPermissionService(),
    inputMonitoringChecker: any InputMonitoringPermissionChecking =
      InputMonitoringPermissionService(),
    windowManagement: any WindowManaging = WindowManagementController(
      service: AccessibilityWindowService()),
    refreshInterval: TimeInterval = 2
  ) {
    self.permissionChecker = permissionChecker
    self.inputMonitoringChecker = inputMonitoringChecker
    self.windowManagement = windowManagement
    self.refreshInterval = refreshInterval
    accessibilityPermission = permissionChecker.isTrusted() ? .available : .unavailable
    inputMonitoringPermission = inputMonitoringChecker.hasAccess() ? .available : .unavailable
    if accessibilityPermission == .unavailable {
      // Ask macOS to show its own Accessibility permission alert once at launch, rather than
      // requiring the user to notice the "Accessibility access required" menu item and open
      // System Settings manually.
      permissionChecker.requestTrust()
      startPolling()
    }
  }

  isolated deinit {
    permissionRefreshTimer?.invalidate()
  }

  func refreshAccessibilityPermission() {
    accessibilityPermission = permissionChecker.isTrusted() ? .available : .unavailable
    // Access is granted for as long as the process runs once macOS trusts it, so there is
    // nothing left to poll for; stop rather than keep waking up the run loop forever.
    if accessibilityPermission == .available {
      permissionRefreshTimer?.invalidate()
      permissionRefreshTimer = nil
    }
  }

  private func startPolling() {
    permissionRefreshTimer = Timer.scheduledTimer(withTimeInterval: refreshInterval, repeats: true)
    { [weak self] _ in
      Task { @MainActor in
        self?.refreshAccessibilityPermission()
      }
    }
  }

  func openAccessibilitySettings() {
    _ = permissionChecker.openSettings()
  }

  func requestInputMonitoringAccess() {
    _ = inputMonitoringChecker.requestAccess()
    inputMonitoringPermission = inputMonitoringChecker.hasAccess() ? .available : .unavailable
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

extension LayoutCommand {
  fileprivate var description: String {
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
