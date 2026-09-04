import Observation
import ServiceManagement

protocol LoginItemManaging: AnyObject {
  var isEnabled: Bool { get }
  func setEnabled(_ isEnabled: Bool) throws
}

@MainActor
@Observable
final class StartAtLoginController {
  private let service: any LoginItemManaging

  private(set) var isEnabled: Bool
  private(set) var errorMessage: String?

  init(service: any LoginItemManaging = SystemLoginItemService()) {
    self.service = service
    isEnabled = service.isEnabled
  }

  func setEnabled(_ isEnabled: Bool) {
    do {
      try service.setEnabled(isEnabled)
      self.isEnabled = service.isEnabled
      errorMessage = nil
    } catch {
      self.isEnabled = service.isEnabled
      errorMessage = "Could not update Start at login."
    }
  }

  func refresh() {
    isEnabled = service.isEnabled
  }
}

private final class SystemLoginItemService: LoginItemManaging {
  var isEnabled: Bool {
    switch SMAppService.mainApp.status {
    case .enabled, .requiresApproval:
      true
    case .notFound, .notRegistered:
      false
    @unknown default:
      false
    }
  }

  func setEnabled(_ isEnabled: Bool) throws {
    let service = SMAppService.mainApp
    if isEnabled {
      guard service.status != .enabled, service.status != .requiresApproval else {
        return
      }
      try service.register()
    } else {
      guard service.status != .notRegistered, service.status != .notFound else {
        return
      }
      try service.unregister()
    }
  }
}
