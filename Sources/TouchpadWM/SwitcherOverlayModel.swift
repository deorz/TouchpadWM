import Observation

@MainActor
@Observable
final class SwitcherOverlayModel {
  private(set) var session: SwitcherSession?

  func show(_ session: SwitcherSession) {
    self.session = session
  }

  func hide() {
    session = nil
  }
}
