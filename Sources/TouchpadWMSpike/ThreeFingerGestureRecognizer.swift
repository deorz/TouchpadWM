enum ThreeFingerGestureEvent: Equatable {
  case began
  case changed(totalVerticalMovement: Float)
  case ended
}

struct ThreeFingerGestureRecognizer {
  private var trackedIDs: Set<Int32>?
  private var originY: Float?

  mutating func consume(_ frame: TouchFrame) -> [ThreeFingerGestureEvent] {
    let currentIDs = Set(frame.contacts.map(\.id))

    guard let trackedIDs, let originY else {
      guard frame.contacts.count == 3, currentIDs.count == 3 else {
        return []
      }

      self.trackedIDs = currentIDs
      self.originY = averageY(in: frame)
      return [.began]
    }

    guard frame.contacts.count == 3, currentIDs == trackedIDs else {
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
