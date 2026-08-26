import CoreGraphics

enum SwitcherOverlayGeometry {
  static let panelWidth: CGFloat = 360
  static let rowHeight: CGFloat = 56
  static let rowSpacing: CGFloat = 4
  static let verticalContentPadding: CGFloat = 12
  static let verticalChrome = verticalContentPadding * 2
  static let maximumVisibleRows = 5

  static func panelSize(forWindowCount count: Int) -> CGSize {
    let visibleRows = min(max(count, 1), maximumVisibleRows)
    return CGSize(
      width: panelWidth,
      height: CGFloat(visibleRows) * rowHeight
        + CGFloat(max(visibleRows - 1, 0)) * rowSpacing
        + verticalChrome)
  }

  static func origin(forPanelSize panelSize: CGSize, centeredIn screenFrame: CGRect) -> CGPoint {
    CGPoint(
      x: screenFrame.midX - panelSize.width / 2,
      y: screenFrame.midY - panelSize.height / 2)
  }
}
