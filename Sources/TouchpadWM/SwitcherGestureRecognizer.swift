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
  static let activationDistance: Float = 0.12
  static let rowDistance: Float = 0.08
  static let maxSelectionChangesPerFrame = 2

  private var activation: PickerActivation
  private var fingerCount: PickerFingerCount
  private var activationSensitivity: GestureSensitivity
  private var sensitivity: GestureSensitivity
  private var gestureRecognizer: MultiFingerGestureRecognizer
  private var lastVerticalMovement: Float = 0
  private var accumulatedMovement: Float = 0
  private var isSwitcherOpen = false

  init(
    activation: PickerActivation = .touch,
    fingerCount: PickerFingerCount = .three,
    activationSensitivity: GestureSensitivity = .medium,
    sensitivity: GestureSensitivity = .medium
  ) {
    self.activation = activation
    self.fingerCount = fingerCount
    self.activationSensitivity = activationSensitivity
    self.sensitivity = sensitivity
    gestureRecognizer = MultiFingerGestureRecognizer(fingerCount: fingerCount.fingerCount)
  }

  mutating func update(
    activation: PickerActivation,
    fingerCount: PickerFingerCount,
    activationSensitivity: GestureSensitivity,
    sensitivity: GestureSensitivity
  ) {
    let hasChanged =
      self.activation != activation || self.fingerCount != fingerCount
      || self.activationSensitivity != activationSensitivity
      || self.sensitivity != sensitivity
    guard hasChanged else {
      return
    }

    self.activation = activation
    self.fingerCount = fingerCount
    self.activationSensitivity = activationSensitivity
    self.sensitivity = sensitivity
    gestureRecognizer = MultiFingerGestureRecognizer(fingerCount: fingerCount.fingerCount)
    lastVerticalMovement = 0
    accumulatedMovement = 0
    isSwitcherOpen = false
  }

  mutating func consume(_ frame: TouchFrame) -> [SwitcherGestureCommand] {
    var commands: [SwitcherGestureCommand] = []
    let epsilon: Float = 0.0001

    for event in gestureRecognizer.consume(frame) {
      switch event {
      case .began:
        lastVerticalMovement = 0
        accumulatedMovement = 0
        isSwitcherOpen = activation == .touch
        if isSwitcherOpen {
          commands.append(.openSwitcher)
        }

      case .changed(let totalVerticalMovement):
        guard isSwitcherOpen else {
          let hasActivated: Bool
          switch activation {
          case .touch:
            hasActivated = false
          case .swipeUp:
            hasActivated =
              totalVerticalMovement >= Self.activationDistance(for: activationSensitivity) - epsilon
          case .swipeDown:
            hasActivated =
              totalVerticalMovement <= -Self.activationDistance(for: activationSensitivity)
              + epsilon
          }

          if hasActivated {
            isSwitcherOpen = true
            lastVerticalMovement = totalVerticalMovement
            accumulatedMovement = 0
            commands.append(.openSwitcher)
          }
          continue
        }

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
        if isSwitcherOpen {
          commands.append(.activateSwitcherSelection)
        }
        isSwitcherOpen = false
      }
    }

    return commands
  }

  private static func activationDistance(for sensitivity: GestureSensitivity) -> Float {
    activationDistance / sensitivity.movementMultiplier
  }
}
