struct WindowActivationSequence {
  @discardableResult
  static func perform(
    activateApplication: () -> Void,
    raiseWindow: () -> Bool,
    focusWindow: () -> Bool
  ) -> Bool {
    activateApplication()
    let raised = raiseWindow()
    let focused = focusWindow()
    return raised && focused
  }
}
