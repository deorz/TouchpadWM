import TouchpadWMSpike

/// Wires the trackpad bridge to the switcher: consumes raw frames, translates them via
/// `SwitcherGestureRecognizer`, and drives `SwitcherController` plus the overlay panel.
@MainActor
final class SwitcherGestureCoordinator {
  private let switcherController: SwitcherController
  private let overlay: SwitcherOverlayPanelController
  private let bridge: MultitouchBridge
  private let scrollSuppressor: ScrollEventSuppressor
  private var recognizer = SwitcherGestureRecognizer()
  private var listenTask: Task<Void, Never>?

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

  private func handle(_ frame: TouchFrame) {
    for command in recognizer.consume(frame) {
      handle(command)
    }
  }

  private func handle(_ command: SwitcherGestureCommand) {
    switch command {
    case .openSwitcher:
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

  /// Scroll suppression tracks the switcher session directly rather than the raw gesture. It
  /// stays off when no eligible windows exist and ends when activation closes the session.
  private func syncScrollSuppression() {
    scrollSuppressor.isSuppressing = switcherController.session != nil
  }
}
