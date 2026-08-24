import AppKit
import ApplicationServices
import CoreGraphics

final class AccessibilityWindowService: AccessibilityWindowServicing {
  private var elements: [WindowID: AXUIElement] = [:]

  func refreshWindows() -> [CataloguedWindow] {
    let metadata = CGWindowListCopyWindowInfo([.optionOnScreenOnly, .excludeDesktopElements], kCGNullWindowID)
      as? [[String: Any]] ?? []
    var refreshedElements: [WindowID: AXUIElement] = [:]
    var windows: [CataloguedWindow] = []

    for application in NSWorkspace.shared.runningApplications where application.processIdentifier > 0 {
      let candidates = metadata.compactMap { candidate(from: $0, processIdentifier: application.processIdentifier) }
      var unusedCandidates = candidates
      let applicationElement = AXUIElementCreateApplication(application.processIdentifier)
      let axWindows = attributeValue(kAXWindowsAttribute as CFString, of: applicationElement) as? [AXUIElement] ?? []

      for axWindow in axWindows {
        let title = (attributeValue(kAXTitleAttribute as CFString, of: axWindow) as? String) ?? ""
        guard let index = unusedCandidates.firstIndex(where: { $0.title == title }) else {
          continue
        }
        let candidate = unusedCandidates.remove(at: index)
        let id = WindowID(processIdentifier: application.processIdentifier, windowNumber: candidate.windowNumber)
        refreshedElements[id] = axWindow
        windows.append(
          CataloguedWindow(
            id: id,
            bundleIdentifier: application.bundleIdentifier ?? "",
            title: title,
            role: role(of: axWindow),
            isMinimized: (attributeValue(kAXMinimizedAttribute as CFString, of: axWindow) as? Bool) ?? false,
            visibleFrame: visibleFrame(containing: candidate.frame)))
      }
    }

    elements = refreshedElements
    return windows
  }

  func focusedWindowID() -> WindowID? {
    let system = AXUIElementCreateSystemWide()
    guard let applicationValue = attributeValue(kAXFocusedApplicationAttribute as CFString, of: system) else {
      return nil
    }
    let application = applicationValue as! AXUIElement
    guard let windowValue = attributeValue(kAXFocusedWindowAttribute as CFString, of: application) else {
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
    guard let position = AXValueCreate(.cgPoint, &origin), let dimensions = AXValueCreate(.cgSize, &size) else {
      return false
    }
    return AXUIElementSetAttributeValue(element, kAXPositionAttribute as CFString, position) == .success
      && AXUIElementSetAttributeValue(element, kAXSizeAttribute as CFString, dimensions) == .success
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
    return Candidate(
      windowNumber: CGWindowID(windowNumber.uint32Value),
      title: (metadata[kCGWindowName as String] as? String) ?? "",
      frame: frame)
  }

  private func attributeValue(_ attribute: CFString, of element: AXUIElement) -> CFTypeRef? {
    var value: CFTypeRef?
    return AXUIElementCopyAttributeValue(element, attribute, &value) == .success ? value : nil
  }

  private func role(of element: AXUIElement) -> WindowRole {
    let role = attributeValue(kAXRoleAttribute as CFString, of: element) as? String
    let subrole = attributeValue(kAXSubroleAttribute as CFString, of: element) as? String
    if role == "AXSheet" { return .sheet }
    if role == "AXDialog" { return .dialog }
    if role == "AXPopover" { return .popover }
    if subrole == "AXFloatingWindow" || subrole == "AXUtilityWindow" { return .floating }
    return role == "AXWindow" ? .normal : .unknown
  }

  private func visibleFrame(containing frame: CGRect) -> CGRect {
    let midpoint = CGPoint(x: frame.midX, y: frame.midY)
    return NSScreen.screens.first(where: { $0.frame.contains(midpoint) })?.visibleFrame
      ?? NSScreen.main?.visibleFrame
      ?? frame
  }
}

private struct Candidate {
  let windowNumber: CGWindowID
  let title: String
  let frame: CGRect
}
