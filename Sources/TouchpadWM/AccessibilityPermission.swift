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
    // kAXTrustedCheckOptionPrompt is imported as a global var without a Sendable overlay. Its
    // stable documented value is used directly to keep this call Swift 6 concurrency-safe.
    _ = AXIsProcessTrustedWithOptions(["AXTrustedCheckOptionPrompt": true] as CFDictionary)
  }
}

@MainActor
@Observable
final class AppState {
  private(set) var accessibilityPermission: AccessibilityPermissionState
  private let permissionChecker: any AccessibilityPermissionChecking
  private let refreshInterval: TimeInterval
  private var permissionRefreshTimer: Timer?

  init(
    permissionChecker: any AccessibilityPermissionChecking = AccessibilityPermissionService(),
    refreshInterval: TimeInterval = 2
  ) {
    self.permissionChecker = permissionChecker
    self.refreshInterval = refreshInterval
    accessibilityPermission = permissionChecker.isTrusted() ? .available : .unavailable
    if accessibilityPermission == .unavailable {
      permissionChecker.requestTrust()
      startPolling()
    }
  }

  isolated deinit {
    permissionRefreshTimer?.invalidate()
  }

  func refreshAccessibilityPermission() {
    accessibilityPermission = permissionChecker.isTrusted() ? .available : .unavailable
    if accessibilityPermission == .available {
      permissionRefreshTimer?.invalidate()
      permissionRefreshTimer = nil
    }
  }

  func openAccessibilitySettings() {
    _ = permissionChecker.openSettings()
  }

  private func startPolling() {
    permissionRefreshTimer = Timer.scheduledTimer(withTimeInterval: refreshInterval, repeats: true)
    { [weak self] _ in
      Task { @MainActor in
        self?.refreshAccessibilityPermission()
      }
    }
  }
}
