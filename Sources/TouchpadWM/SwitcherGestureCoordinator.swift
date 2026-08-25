import TouchpadWMSpike

/// Wires the trackpad bridge to the switcher: consumes raw frames, translates them via
/// `SwitcherGestureRecognizer`, and drives `SwitcherController` plus the overlay panel.
/// `isRightOptionPressed` gates `openSwitcher`: while Right Option is held it is reserved for
/// layout gestures (per the V1 command router), so the switcher does not open. Any later
/// `moveSwitcherSelection`/`activateSwitcherSelection` commands are harmless no-ops when no
/// session is open, so no further gating is needed for them.
@MainActor
final class SwitcherGestureCoordinator {
  private let switcherController: SwitcherController
  private let overlay: SwitcherOverlayPanelController
  private let bridge: MultitouchBridge
  private let scrollSuppressor: ScrollEventSuppressor
  private var recognizer = SwitcherGestureRecognizer()
  private var listenTask: Task<Void, Never>?

  var isRightOptionPressed = false

  init(
    switcherController: SwitcherController,
    overlay: SwitcherOverlayPanelController,
    bridge: MultitouchBridge = MultitouchBridge(),
    scrollSuppressor: ScrollEventSuppressor = ScrollEventSuppressor()
  ) {
    self.switcherController = switcherController
    self.overlay = overlay
    self.bridge = bridge
    self.scrollSuppressor = scrollSuppressor
  }

  func start() {
    scrollSuppressor.start()
    guard listenTask == nil, bridge.start() else {
      return
    }
    listenTask = Task { [bridge] in
      for await frame in bridge.frames() {
        self.handle(frame)
      }
    }
  }

  func cancelOpenSession() {
    guard switcherController.session != nil else {
      return
    }
    switcherController.cancel()
    overlay.hide()
    syncScrollSuppression()
  }

  private func handle(_ frame: TouchFrame) {
    for command in recognizer.consume(frame) {
      handle(command)
    }
  }

  private func handle(_ command: SwitcherGestureCommand) {
    switch command {
    case .openSwitcher:
      guard !isRightOptionPressed else {
        return
      }
      switcherController.open()
      presentCurrentSession()

    case .moveSwitcherSelection(let direction):
      switcherController.moveSelection(direction)
      presentCurrentSession()

    case .activateSwitcherSelection:
      switcherController.activateSelection()
      overlay.hide()
      syncScrollSuppression()
    }
  }

  private func presentCurrentSession() {
    if let session = switcherController.session {
      overlay.show(session)
    } else {
      overlay.hide()
    }
    syncScrollSuppression()
  }

  /// Scroll suppression tracks the switcher session directly rather than the raw gesture: this
  /// keeps it off whenever the switcher itself doesn't open (Right Option held, or no eligible
  /// windows), and off as soon as the overlay closes for any reason (activation or cancel).
  private func syncScrollSuppression() {
    scrollSuppressor.isSuppressing = switcherController.session != nil
  }
}
