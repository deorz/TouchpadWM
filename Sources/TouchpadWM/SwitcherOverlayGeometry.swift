import CoreGraphics

enum SwitcherOverlayGeometry {
  static func origin(forPanelSize panelSize: CGSize, centeredIn screenFrame: CGRect) -> CGPoint {
    CGPoint(
      x: screenFrame.midX - panelSize.width / 2,
      y: screenFrame.midY - panelSize.height / 2)
  }
}
