import TouchpadWMSpike

enum SwitcherDirection: Equatable {
  case previous
  case next
}

enum SwitcherGestureCommand: Equatable {
  case openSwitcher
  case moveSwitcherSelection(SwitcherDirection)
  case activateSwitcherSelection
}

/// Wraps the shared `ThreeFingerGestureRecognizer` to translate its raw, continuous
/// vertical-movement stream into the switcher's semantic command vocabulary. The underlying
/// recognizer is untouched and still shared as-is with `TouchpadWMSpike`.
struct SwitcherGestureRecognizer {
  static let rowSelectionThreshold: Float = 0.15

  private var gestureRecognizer = ThreeFingerGestureRecognizer()
  private var distanceConsumed: Float = 0

  init() {}

  mutating func consume(_ frame: TouchFrame) -> [SwitcherGestureCommand] {
    var commands: [SwitcherGestureCommand] = []
    let epsilon: Float = 0.0001

    for event in gestureRecognizer.consume(frame) {
      switch event {
      case .began:
        distanceConsumed = 0
        commands.append(.openSwitcher)

      case .changed(let totalVerticalMovement):
        while totalVerticalMovement - distanceConsumed >= Self.rowSelectionThreshold - epsilon {
          distanceConsumed += Self.rowSelectionThreshold
          commands.append(.moveSwitcherSelection(.previous))
        }
        while distanceConsumed - totalVerticalMovement >= Self.rowSelectionThreshold - epsilon {
          distanceConsumed -= Self.rowSelectionThreshold
          commands.append(.moveSwitcherSelection(.next))
        }

      case .ended:
        commands.append(.activateSwitcherSelection)
      }
    }

    return commands
  }
}
