import Combine
import CoreServices

/// Presentation requests are independent of menu bar visibility and Accessibility access.
/// A sequence number lets the scene observe repeated reopen events, even after Settings closes.
@MainActor
final class ApplicationLifecycle: ObservableObject {
  @Published private(set) var settingsRequestID = 0
  private var receivedOpenApplication = false

  func handleOpenApplication(launchProperty: UInt32?) {
    receivedOpenApplication = true
    // SMAppService.mainApp supplies 'lgit' in the open event's keyAEPropData parameter.
    guard launchProperty != UInt32(keyAELaunchedAsLogInItem),
      launchProperty != UInt32(keyAELaunchedAsServiceItem)
    else {
      return
    }
    handleReopen()
  }

  func didFinishLaunching() {
    // Launch Services delivers open-application before didFinishLaunching. Running the
    // executable directly (e.g. swift run) may not supply an Apple event at all.
    if !receivedOpenApplication {
      handleReopen()
    }
  }

  func handleReopen() {
    settingsRequestID += 1
  }
}
