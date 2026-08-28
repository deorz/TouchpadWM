enum SwitcherHapticFeedback: Equatable {
  case alignment
  case generic
}

/// Decides which trackpad haptic, if any, accompanies a switcher gesture command. Kept free of
/// AppKit so it stays unit-testable; `SwitcherGestureCoordinator` performs the actual feedback.
enum SwitcherHapticPolicy {
  static func feedback(for command: SwitcherGestureCommand) -> SwitcherHapticFeedback {
    feedback(for: command, strength: .standard)!
  }

  static func feedback(
    for command: SwitcherGestureCommand,
    strength: HapticFeedbackStrength
  ) -> SwitcherHapticFeedback? {
    switch strength {
    case .off:
      return nil
    case .light:
      return .alignment
    case .strong:
      return .generic
    case .standard:
      return standardFeedback(for: command)
    }
  }

  private static func standardFeedback(
    for command: SwitcherGestureCommand
  ) -> SwitcherHapticFeedback {
    switch command {
    case .openSwitcher, .activateSwitcherSelection:
      return .generic
    case .moveSwitcherSelection:
      return .alignment
    }
  }
}
