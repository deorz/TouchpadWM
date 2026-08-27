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
  static let rowDistance: Float = 0.08
  static let sensitivity: Float = 1.0
  static let maxSelectionChangesPerFrame = 2

  private var gestureRecognizer = ThreeFingerGestureRecognizer()
  private var lastVerticalMovement: Float = 0
  private var accumulatedMovement: Float = 0

  init() {}

  mutating func consume(_ frame: TouchFrame) -> [SwitcherGestureCommand] {
    var commands: [SwitcherGestureCommand] = []
    let epsilon: Float = 0.0001

    for event in gestureRecognizer.consume(frame) {
      switch event {
      case .began:
        lastVerticalMovement = 0
        accumulatedMovement = 0
        commands.append(.openSwitcher)

      case .changed(let totalVerticalMovement):
        let delta = totalVerticalMovement - lastVerticalMovement
        lastVerticalMovement = totalVerticalMovement
        accumulatedMovement += delta * Self.sensitivity

        var selectionChanges = 0
        while accumulatedMovement >= Self.rowDistance - epsilon,
          selectionChanges < Self.maxSelectionChangesPerFrame
        {
          accumulatedMovement -= Self.rowDistance
          commands.append(.moveSwitcherSelection(.previous))
          selectionChanges += 1
        }
        while accumulatedMovement <= -Self.rowDistance + epsilon,
          selectionChanges < Self.maxSelectionChangesPerFrame
        {
          accumulatedMovement += Self.rowDistance
          commands.append(.moveSwitcherSelection(.next))
          selectionChanges += 1
        }

      case .ended:
        commands.append(.activateSwitcherSelection)
      }
    }

    return commands
  }
}
