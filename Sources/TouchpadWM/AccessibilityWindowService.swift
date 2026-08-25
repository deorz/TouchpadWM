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
    // CGWindowListCopyWindowInfo does not enumerate windows on Spaces other than the active one,
    // regardless of .optionOnScreenOnly -- that limitation is unconditional, not gated by that
    // flag. So this metadata is used only to enrich a window's frame when it happens to be
    // available (the current Space); it is never a requirement for a window to be catalogued.
    // Enumeration itself walks each running application's AX windows directly, which does
    // include windows on other Spaces, so cross-Space windows stay reachable for the switcher
    // (the switcher and layout share this one catalogue source -- see
    // WindowManagementController). Cross-Space/display activation is expected to work per the
    // design spec ("delegated to the existing Accessibility window activation path").
    let metadata =
      CGWindowListCopyWindowInfo([.excludeDesktopElements], kCGNullWindowID)
      as? [[String: Any]] ?? []
    var refreshedElements: [WindowID: AXUIElement] = [:]
    var windows: [CataloguedWindow] = []

    for application in NSWorkspace.shared.runningApplications
    where application.processIdentifier > 0 && application.activationPolicy != .prohibited {
      // Restrict the (slow, synchronous, cross-process) AX window query to applications that can
      // plausibly own windows at all. Without this, every background/helper process -- most of
      // which don't support Accessibility and can each cost up to a full AX timeout -- gets
      // queried too, stalling this call long enough to visibly stutter the switcher. This used to
      // be a side effect of requiring a CGWindowList entry, which is no longer required (see
      // above), so it needs restoring explicitly; activationPolicy is an in-process property read
      // with no IPC cost, unlike the AX query it's guarding.
      let candidatesByWindowNumber = Dictionary(
        uniqueKeysWithValues: metadata.compactMap {
          candidate(from: $0, processIdentifier: application.processIdentifier)
        }.map { ($0.windowNumber, $0) })
      let applicationElement = AXUIElementCreateApplication(application.processIdentifier)
      let axWindows =
        attributeValue(kAXWindowsAttribute as CFString, of: applicationElement) as? [AXUIElement]
        ?? []

      for axWindow in axWindows {
        var windowNumber: CGWindowID = 0
        guard _AXUIElementGetWindow(axWindow, &windowNumber) == .success else {
          continue
        }
        guard let frame = candidatesByWindowNumber[windowNumber]?.frame ?? axFrame(of: axWindow)
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
            title: (attributeValue(kAXTitleAttribute as CFString, of: axWindow) as? String) ?? "",
            role: role(of: axWindow),
            isMinimized: (attributeValue(kAXMinimizedAttribute as CFString, of: axWindow) as? Bool)
              ?? false,
            visibleFrame: visibleFrame(containing: frame)))
      }
    }

    elements = refreshedElements
    return windows
  }

  /// Falls back to the AX position/size attributes for a window's frame when CGWindowList has no
  /// entry for it -- the case for every window on an inactive Space, which CGWindowList never
  /// reports regardless of options.
  private func axFrame(of element: AXUIElement) -> CGRect? {
    guard
      let positionValue = attributeValue(kAXPositionAttribute as CFString, of: element),
      let sizeValue = attributeValue(kAXSizeAttribute as CFString, of: element)
    else {
      return nil
    }
    var origin = CGPoint.zero
    var size = CGSize.zero
    guard AXValueGetValue(positionValue as! AXValue, .cgPoint, &origin),
      AXValueGetValue(sizeValue as! AXValue, .cgSize, &size)
    else {
      return nil
    }
    return CGRect(origin: origin, size: size)
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

  func apply(_ frame: CGRect, to id: WindowID) -> Bool {
    guard let element = elements[id] else {
      return false
    }
    var origin = frame.origin
    var size = frame.size
    guard let position = AXValueCreate(.cgPoint, &origin),
      let dimensions = AXValueCreate(.cgSize, &size)
    else {
      return false
    }
    return AXUIElementSetAttributeValue(element, kAXPositionAttribute as CFString, position)
      == .success
      && AXUIElementSetAttributeValue(element, kAXSizeAttribute as CFString, dimensions) == .success
  }

  func activate(_ id: WindowID) -> Bool {
    guard let element = elements[id] else {
      return false
    }
    let raised = AXUIElementPerformAction(element, kAXRaiseAction as CFString) == .success
    let focused =
      AXUIElementSetAttributeValue(element, kAXFocusedAttribute as CFString, kCFBooleanTrue)
      == .success
    if let application = NSRunningApplication(processIdentifier: id.processIdentifier) {
      application.activate()
    }
    return raised && focused
  }

  private func candidate(from metadata: [String: Any], processIdentifier: pid_t) -> Candidate? {
    guard (metadata[kCGWindowOwnerPID as String] as? NSNumber)?.int32Value == processIdentifier,
      let windowNumber = metadata[kCGWindowNumber as String] as? NSNumber,
      let rawBounds = metadata[kCGWindowBounds as String]
    else {
      return nil
    }
    let bounds = rawBounds as! CFDictionary
    guard let frame = CGRect(dictionaryRepresentation: bounds) else {
      return nil
    }
    return Candidate(windowNumber: CGWindowID(windowNumber.uint32Value), frame: frame)
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
  let frame: CGRect
}
