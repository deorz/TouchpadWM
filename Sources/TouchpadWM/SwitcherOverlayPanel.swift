import AppKit
import SwiftUI

/// Hosts `SwitcherOverlayView` in a non-activating panel. This is an AppKit adapter boundary
/// (like `AccessibilityWindowService`): it owns no decision logic beyond what
/// `SwitcherOverlayGeometry` already provides pure and tested.
@MainActor
final class SwitcherOverlayPanelController {
  private var panel: NSPanel?

  func show(_ session: SwitcherSession) {
    let panel = panel ?? makePanel()
    self.panel = panel
    panel.contentView = NSHostingView(rootView: SwitcherOverlayView(session: session))
    panel.layoutIfNeeded()
    if let screen = NSScreen.main {
      let origin = SwitcherOverlayGeometry.origin(
        forPanelSize: panel.frame.size, centeredIn: screen.frame)
      panel.setFrameOrigin(origin)
    }
    panel.orderFrontRegardless()
  }

  func hide() {
    panel?.orderOut(nil)
  }

  private func makePanel() -> NSPanel {
    let panel = NSPanel(
      contentRect: NSRect(x: 0, y: 0, width: 280, height: 200),
      styleMask: [.nonactivatingPanel, .borderless],
      backing: .buffered,
      defer: false)
    panel.level = .floating
    panel.isFloatingPanel = true
    panel.hidesOnDeactivate = false
    panel.isOpaque = false
    panel.backgroundColor = .clear
    return panel
  }
}
