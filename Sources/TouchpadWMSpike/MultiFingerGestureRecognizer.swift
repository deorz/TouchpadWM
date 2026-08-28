public enum MultiFingerGestureEvent: Equatable {
  case began
  case changed(totalVerticalMovement: Float)
  case ended
}

public struct MultiFingerGestureRecognizer {
  private let requiredFingerCount: Int
  private var trackedIDs: Set<Int32>?
  private var originY: Float?

  public init() {
    self.init(fingerCount: 3)
  }

  public init(fingerCount: Int) {
    requiredFingerCount = max(fingerCount, 1)
  }

  public mutating func consume(_ frame: TouchFrame) -> [MultiFingerGestureEvent] {
    let currentIDs = Set(frame.contacts.map(\.id))

    guard let trackedIDs, let originY else {
      guard frame.contacts.count == requiredFingerCount,
        currentIDs.count == requiredFingerCount
      else {
        return []
      }

      self.trackedIDs = currentIDs
      self.originY = averageY(in: frame)
      return [.began]
    }

    guard frame.contacts.count == requiredFingerCount, currentIDs == trackedIDs else {
      self.trackedIDs = nil
      self.originY = nil
      return [.ended]
    }

    return [.changed(totalVerticalMovement: averageY(in: frame) - originY)]
  }

  private func averageY(in frame: TouchFrame) -> Float {
    frame.contacts.map(\.y).reduce(0, +) / Float(frame.contacts.count)
  }
}
