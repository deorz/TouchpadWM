import SwiftUI

/// A thin, logic-free renderer of a `SwitcherSession`. All selection and ordering decisions
/// live in `SwitcherController`; this view only draws the snapshot it is given, bottom-to-top
/// per the V1 design (the current window at index 0 renders at the bottom).
struct SwitcherOverlayView: View {
  let session: SwitcherSession

  var body: some View {
    VStack(spacing: 4) {
      ForEach(Array(session.windows.enumerated()).reversed(), id: \.element.id) { index, window in
        Text(window.title.isEmpty ? window.bundleIdentifier : window.title)
          .lineLimit(1)
          .padding(.horizontal, 12)
          .padding(.vertical, 6)
          .frame(maxWidth: .infinity, alignment: .leading)
          .background(
            index == session.selectedIndex
              ? Color.accentColor.opacity(0.3) : Color.clear)
      }
    }
    .padding(8)
    .frame(minWidth: 240, maxHeight: 320)
    .background(.regularMaterial)
  }
}

extension CataloguedWindow: Identifiable {}
