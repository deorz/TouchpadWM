import AppKit
import ApplicationServices
import CoreGraphics

/// Resolves the CGWindowID owned by an AXUIElement window. ApplicationServices does not expose
/// this mapping publicly; every major macOS window manager (AeroSpace, yabai, AltTab) relies on
/// this same private symbol because title- or geometry-based matching is ambiguous whenever two
/// windows of one app share a title. Confine this private-symbol use to this file, mirroring how
/// MultitouchBridge.swift isolates its own private-framework access.
@_silgen_name("_AXUIElementGetWindow")
@discardableResult
private func _AXUIElementGetWindow(_ element: AXUIElement, _ identifier: inout CGWindowID)
  -> AXError

final class AccessibilityWindowService: AccessibilityWindowServicing {
  private var elements: [WindowID: AXUIElement] = [:]

  func refreshWindows() -> [CataloguedWindow] {
    // No .optionOnScreenOnly: that flag excludes windows on other Spaces entirely, which would
    // make them unreachable from the picker. Cross-Space/display activation is expected to work,
    // so enumeration must surface those windows for AccessibilityWindowService.activate to have
    // anything to act on.
    let metadata =
      CGWindowListCopyWindowInfo([.excludeDesktopElements], kCGNullWindowID)
      as? [[String: Any]] ?? []
    var refreshedElements: [WindowID: AXUIElement] = [:]
    var windows: [CataloguedWindow] = []

    for application in NSWorkspace.shared.runningApplications
    where application.processIdentifier > 0 {
      let candidatesByWindowNumber = Dictionary(
        uniqueKeysWithValues: metadata.compactMap {
          candidate(from: $0, processIdentifier: application.processIdentifier)
        }.map { ($0.windowNumber, $0) })
      guard !candidatesByWindowNumber.isEmpty else {
        continue
      }
      let applicationElement = AXUIElementCreateApplication(application.processIdentifier)
      let axWindows =
        attributeValue(kAXWindowsAttribute as CFString, of: applicationElement) as? [AXUIElement]
        ?? []

      for axWindow in axWindows {
        var windowNumber: CGWindowID = 0
        guard _AXUIElementGetWindow(axWindow, &windowNumber) == .success,
          let candidate = candidatesByWindowNumber[windowNumber]
        else {
          continue
        }
        guard
          PickerWindowEligibility.shouldInclude(
            bundleIdentifier: application.bundleIdentifier,
            windowLayer: candidate.layer,
            frame: candidate.frame)
        else {
          continue
        }
        let id = WindowID(
          processIdentifier: application.processIdentifier, windowNumber: windowNumber)
        refreshedElements[id] = axWindow
        windows.append(
          CataloguedWindow(
            id: id,
            bundleIdentifier: application.bundleIdentifier ?? "",
            applicationName: application.localizedName ?? application.bundleIdentifier ?? "",
            title: (attributeValue(kAXTitleAttribute as CFString, of: axWindow) as? String) ?? "",
            role: role(of: axWindow),
            isMinimized: (attributeValue(kAXMinimizedAttribute as CFString, of: axWindow) as? Bool)
              ?? false,
            visibleFrame: visibleFrame(containing: candidate.frame)))
      }
    }

    elements = refreshedElements
    return windows
  }

  func focusedWindowID() -> WindowID? {
    let system = AXUIElementCreateSystemWide()
    guard
      let applicationValue = attributeValue(kAXFocusedApplicationAttribute as CFString, of: system)
    else {
      return nil
    }
    // `as?` to a CoreFoundation type here is flagged by the compiler as an unconditional cast
    // (AXUIElement bridges as a type-erased CFTypeRef, with no runtime CFGetTypeID check either
    // way), so `as!` is required and is not a genuine crash risk.
    let application = applicationValue as! AXUIElement
    guard let windowValue = attributeValue(kAXFocusedWindowAttribute as CFString, of: application)
    else {
      return nil
    }
    let focusedWindow = windowValue as! AXUIElement
    return elements.first(where: { CFEqual($0.value, focusedWindow) })?.key
  }

  func activate(_ id: WindowID) -> Bool {
    guard let element = elements[id] else {
      return false
    }
    let application = NSRunningApplication(processIdentifier: id.processIdentifier)
    // Accessory apps must be active before AX raises or focuses one of their windows. In
    // particular, this is required for the app's SwiftUI Settings scene to come forward from the
    // picker; the menubar action already follows this order explicitly.
    return WindowActivationSequence.perform(
      activateApplication: { application?.activate() },
      raiseWindow: {
        AXUIElementPerformAction(element, kAXRaiseAction as CFString) == .success
      },
      focusWindow: {
        AXUIElementSetAttributeValue(element, kAXFocusedAttribute as CFString, kCFBooleanTrue)
          == .success
      })
  }

  private func candidate(from metadata: [String: Any], processIdentifier: pid_t) -> Candidate? {
    guard (metadata[kCGWindowOwnerPID as String] as? NSNumber)?.int32Value == processIdentifier,
      let windowNumber = metadata[kCGWindowNumber as String] as? NSNumber,
      let layer = metadata[kCGWindowLayer as String] as? NSNumber,
      let rawBounds = metadata[kCGWindowBounds as String]
    else {
      return nil
    }
    let bounds = rawBounds as! CFDictionary
    guard let frame = CGRect(dictionaryRepresentation: bounds) else {
      return nil
    }
    return Candidate(
      windowNumber: CGWindowID(windowNumber.uint32Value),
      layer: layer.intValue,
      frame: frame)
  }

  private func attributeValue(_ attribute: CFString, of element: AXUIElement) -> CFTypeRef? {
    var value: CFTypeRef?
    return AXUIElementCopyAttributeValue(element, attribute, &value) == .success ? value : nil
  }

  private func role(of element: AXUIElement) -> WindowRole {
    AccessibilityWindowMetadata.role(
      role: attributeValue(kAXRoleAttribute as CFString, of: element) as? String,
      subrole: attributeValue(kAXSubroleAttribute as CFString, of: element) as? String)
  }

  private func visibleFrame(containing frame: CGRect) -> CGRect {
    let midpoint = CGPoint(x: frame.midX, y: frame.midY)
    let screens = NSScreen.screens
    let desktopTop = screens.map(\.frame.maxY).max() ?? frame.maxY
    let screen =
      screens.first(where: {
        accessibilityFrame(for: $0.frame, desktopTop: desktopTop).contains(midpoint)
      }) ?? NSScreen.main

    guard let screen else {
      return frame
    }
    return accessibilityFrame(for: screen.visibleFrame, desktopTop: desktopTop)
  }

  private func accessibilityFrame(for frame: CGRect, desktopTop: CGFloat) -> CGRect {
    CGRect(
      x: frame.minX,
      y: desktopTop - frame.maxY,
      width: frame.width,
      height: frame.height)
  }
}

private struct Candidate {
  let windowNumber: CGWindowID
  let layer: Int
  let frame: CGRect
}
