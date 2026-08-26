import AppKit
import SwiftUI

/// Hosts the picker renderer in a non-activating panel. This is an AppKit adapter boundary:
/// pure sizing/placement stays in `SwitcherOverlayGeometry`, and row-label decisions stay in
/// `WindowPickerRowPresentation`.
@MainActor
final class SwitcherOverlayPanelController {
  private var panel: NSPanel?

  func show(_ session: SwitcherSession) {
    let panel = panel ?? makePanel()
    self.panel = panel
    let panelSize = SwitcherOverlayGeometry.panelSize(forWindowCount: session.windows.count)
    panel.setContentSize(panelSize)
    panel.contentView = NSHostingView(rootView: SwitcherOverlayView(session: session))
    if let screen = NSScreen.main {
      let origin = SwitcherOverlayGeometry.origin(
        forPanelSize: panelSize, centeredIn: screen.frame)
      panel.setFrameOrigin(origin)
    }
    panel.orderFrontRegardless()
  }

  func hide() {
    panel?.orderOut(nil)
  }

  private func makePanel() -> NSPanel {
    let panel = NSPanel(
      contentRect: NSRect(
        origin: .zero,
        size: SwitcherOverlayGeometry.panelSize(forWindowCount: 1)),
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

@MainActor
private struct SwitcherOverlayView: View {
  let session: SwitcherSession
  @State private var iconCache = ApplicationIconCache()

  var body: some View {
    ScrollViewReader { proxy in
      ScrollView {
        VStack(spacing: 4) {
          ForEach(Array(session.windows.enumerated()).reversed(), id: \.element.id) {
            index, window in
            SwitcherOverlayRow(
              presentation: WindowPickerRowPresentation(window: window),
              isSelected: index == session.selectedIndex,
              icon: iconCache.icon(forBundleIdentifier: window.bundleIdentifier)
            )
            .id(index)
          }
        }
        .padding(12)
      }
      .scrollIndicators(.hidden)
      .onAppear {
        proxy.scrollTo(session.selectedIndex, anchor: .bottom)
      }
      .onChange(of: session.selectedIndex) { _, selectedIndex in
        withAnimation(.easeOut(duration: 0.15)) {
          proxy.scrollTo(selectedIndex, anchor: .center)
        }
      }
    }
    .background(.regularMaterial)
    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    .shadow(color: .black.opacity(0.22), radius: 18, y: 8)
  }
}

private struct SwitcherOverlayRow: View {
  let presentation: WindowPickerRowPresentation
  let isSelected: Bool
  let icon: NSImage

  var body: some View {
    HStack(spacing: 12) {
      Image(nsImage: icon)
        .resizable()
        .frame(width: 32, height: 32)

      VStack(alignment: .leading, spacing: 2) {
        Text(presentation.primaryTitle)
          .lineLimit(1)
          .truncationMode(.tail)
          .foregroundStyle(.primary)
        if let secondaryTitle = presentation.secondaryTitle {
          Text(secondaryTitle)
            .font(.caption)
            .lineLimit(1)
            .truncationMode(.tail)
            .foregroundStyle(.secondary)
        }
      }
      Spacer(minLength: 0)
    }
    .padding(.horizontal, 12)
    .frame(maxWidth: .infinity, minHeight: SwitcherOverlayGeometry.rowHeight, alignment: .leading)
    .background {
      RoundedRectangle(cornerRadius: 10, style: .continuous)
        .fill(isSelected ? Color.accentColor.opacity(0.25) : .clear)
    }
  }
}
