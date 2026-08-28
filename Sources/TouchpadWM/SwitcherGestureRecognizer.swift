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

/// Wraps the shared `MultiFingerGestureRecognizer` to translate its raw, continuous
/// vertical-movement stream into the switcher's semantic command vocabulary. The underlying
/// recognizer is untouched and still shared as-is with `TouchpadWMSpike`.
struct SwitcherGestureRecognizer {
  static let rowDistance: Float = 0.08
  static let maxSelectionChangesPerFrame = 2

  private var trigger: PickerTrigger
  private var sensitivity: GestureSensitivity
  private var gestureRecognizer: MultiFingerGestureRecognizer
  private var lastVerticalMovement: Float = 0
  private var accumulatedMovement: Float = 0

  init(
    trigger: PickerTrigger = .threeFingers,
    sensitivity: GestureSensitivity = .medium
  ) {
    self.trigger = trigger
    self.sensitivity = sensitivity
    gestureRecognizer = MultiFingerGestureRecognizer(fingerCount: trigger.fingerCount)
  }

  mutating func update(
    trigger: PickerTrigger,
    sensitivity: GestureSensitivity
  ) {
    guard self.trigger != trigger || self.sensitivity != sensitivity else {
      return
    }

    self.trigger = trigger
    self.sensitivity = sensitivity
    gestureRecognizer = MultiFingerGestureRecognizer(fingerCount: trigger.fingerCount)
    lastVerticalMovement = 0
    accumulatedMovement = 0
  }

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
        accumulatedMovement += delta * sensitivity.movementMultiplier

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
