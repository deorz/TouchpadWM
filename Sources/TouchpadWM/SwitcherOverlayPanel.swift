import AppKit
import SwiftUI

/// Hosts the picker renderer in a non-activating panel. This is an AppKit adapter boundary:
/// pure sizing/placement stays in `SwitcherOverlayGeometry`, and row-label decisions stay in
/// `WindowPickerRowPresentation`.
@MainActor
final class SwitcherOverlayPanelController {
  private let model = SwitcherOverlayModel()
  private let preferences: GesturePreferences
  private var panel: NSPanel?

  init(preferences: GesturePreferences = GesturePreferences()) {
    self.preferences = preferences
  }

  func show(_ session: SwitcherSession) {
    let panel = panel ?? makePanel()
    self.panel = panel
    let screen = NSScreen.main
    let panelSize = SwitcherOverlayGeometry.panelSize(
      forWindowCount: session.windows.count,
      width: preferences.pickerWidth,
      maximumVisibleRows: preferences.pickerVisibleRows,
      fittingIn: screen?.visibleFrame)
    panel.setContentSize(panelSize)
    model.show(session)
    if let screen {
      let origin = SwitcherOverlayGeometry.origin(
        forPanelSize: panelSize, centeredIn: screen.visibleFrame)
      panel.setFrameOrigin(origin)
    }
    panel.orderFrontRegardless()
  }

  func hide() {
    model.hide()
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
    panel.hasShadow = true
    panel.hidesOnDeactivate = false
    panel.isOpaque = false
    panel.backgroundColor = .clear
    panel.contentView = NSHostingView(
      rootView: SwitcherOverlayView(model: model, preferences: preferences))
    return panel
  }
}

@MainActor
private struct SwitcherOverlayView: View {
  let model: SwitcherOverlayModel
  let preferences: GesturePreferences
  @State private var iconCache = ApplicationIconCache()

  var body: some View {
    Group {
      if let session = model.session {
        ScrollViewReader { proxy in
          ScrollView {
            VStack(spacing: 0) {
              Color.clear
                .frame(height: SwitcherOverlayGeometry.verticalContentPadding)

              VStack(spacing: SwitcherOverlayGeometry.rowSpacing) {
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
              .padding(.horizontal, 12)

              Color.clear
                .frame(height: SwitcherOverlayGeometry.verticalContentPadding)
                .id(PickerScrollAnchor.bottomPadding)
            }
          }
          .scrollIndicators(
            SwitcherOverlayGeometry.showsScrollIndicator(
              forWindowCount: session.windows.count,
              maximumVisibleRows: preferences.pickerVisibleRows)
              ? .visible : .hidden
          )
          .contentMargins(
            .vertical,
            SwitcherOverlayGeometry.scrollIndicatorVerticalInset,
            for: .scrollIndicators
          )
          .onAppear {
            scrollToInitialSelection(in: session, using: proxy)
          }
          .onChange(of: model.session) { oldSession, newSession in
            guard let newSession else {
              return
            }
            if oldSession == nil {
              scrollToInitialSelection(in: newSession, using: proxy)
            } else if oldSession?.selectedIndex != newSession.selectedIndex {
              withAnimation(.easeOut(duration: 0.06)) {
                proxy.scrollTo(newSession.selectedIndex, anchor: .center)
              }
            }
          }
        }
      } else {
        Color.clear
      }
    }
    .modifier(PickerSurface())
  }

  private func scrollToInitialSelection(in session: SwitcherSession, using proxy: ScrollViewProxy) {
    if session.selectedIndex == 0 {
      proxy.scrollTo(PickerScrollAnchor.bottomPadding, anchor: .bottom)
    } else {
      proxy.scrollTo(session.selectedIndex, anchor: .center)
    }
  }
}

private struct PickerSurface: ViewModifier {
  @ViewBuilder
  func body(content: Content) -> some View {
    if #available(macOS 26.0, *) {
      content
        .glassEffect(.regular, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
    } else {
      content
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
  }
}

private enum PickerScrollAnchor {
  static let bottomPadding = "bottom-padding"
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
