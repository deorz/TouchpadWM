import CoreGraphics

enum LayoutZone: Equatable {
  case masterStack
  case leftThreeQuarters
  case rightQuarter
  case leftHalf
  case rightHalf
  case topRightQuarter
  case bottomRightQuarter
}

enum LayoutGeometry {
  static let gap = 8.0

  static func frame(for zone: LayoutZone, in visibleFrame: CGRect) -> CGRect {
    let insetFrame = visibleFrame.insetBy(dx: gap, dy: gap)

    return switch zone {
    case .masterStack:
      insetFrame
    case .leftHalf:
      horizontalFrames(in: insetFrame, leftRatio: 1).left
    case .rightHalf:
      horizontalFrames(in: insetFrame, leftRatio: 1).right
    case .leftThreeQuarters:
      horizontalFrames(in: insetFrame, leftRatio: 3).left
    case .rightQuarter:
      horizontalFrames(in: insetFrame, leftRatio: 3).right
    case .topRightQuarter:
      verticalFrames(in: horizontalFrames(in: insetFrame, leftRatio: 1).right).top
    case .bottomRightQuarter:
      verticalFrames(in: horizontalFrames(in: insetFrame, leftRatio: 1).right).bottom
    }
  }

  private static func horizontalFrames(in frame: CGRect, leftRatio: CGFloat) -> (
    left: CGRect, right: CGRect
  ) {
    let availableWidth = frame.width - gap
    let leftWidth = availableWidth * leftRatio / (leftRatio + 1)
    let rightWidth = availableWidth - leftWidth
    let left = CGRect(x: frame.minX, y: frame.minY, width: leftWidth, height: frame.height)
    let right = CGRect(x: left.maxX + gap, y: frame.minY, width: rightWidth, height: frame.height)
    return (left, right)
  }

  private static func verticalFrames(in frame: CGRect) -> (top: CGRect, bottom: CGRect) {
    let height = (frame.height - gap) / 2
    let top = CGRect(x: frame.minX, y: frame.minY, width: frame.width, height: height)
    let bottom = CGRect(x: frame.minX, y: top.maxY + gap, width: frame.width, height: height)
    return (top, bottom)
  }
}

extension LayoutCommand {
  var zone: LayoutZone {
    switch self {
    case .leftHalf: .leftHalf
    case .rightHalf: .rightHalf
    case .leftThreeQuarters: .leftThreeQuarters
    case .rightQuarter: .rightQuarter
    case .topRightQuarter: .topRightQuarter
    case .bottomRightQuarter: .bottomRightQuarter
    case .masterStack: .masterStack
    }
  }
}
