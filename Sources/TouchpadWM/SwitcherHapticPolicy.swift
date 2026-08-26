enum SwitcherHapticFeedback: Equatable {
  case alignment
  case generic
}

/// Decides which trackpad haptic, if any, accompanies a switcher gesture command. Kept free of
/// AppKit so it stays unit-testable; `SwitcherGestureCoordinator` performs the actual feedback.
enum SwitcherHapticPolicy {
  static func feedback(for command: SwitcherGestureCommand) -> SwitcherHapticFeedback {
    switch command {
    case .openSwitcher, .activateSwitcherSelection:
      return .generic
    case .moveSwitcherSelection:
      return .alignment
    }
  }
}
