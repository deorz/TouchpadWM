import CoreServices
import XCTest

@testable import TouchpadWM

@MainActor
final class ApplicationLifecycleTests: XCTestCase {
  func testManualLaunchRequestsSettingsOnce() {
    let lifecycle = ApplicationLifecycle()

    lifecycle.handleOpenApplication(launchProperty: nil)
    lifecycle.didFinishLaunching()

    XCTAssertEqual(lifecycle.settingsRequestID, 1)
  }

  func testLoginAndServiceLaunchesStayQuietButAllowRepeatedReopening() {
    for property in [keyAELaunchedAsLogInItem, keyAELaunchedAsServiceItem] {
      let lifecycle = ApplicationLifecycle()
      lifecycle.handleOpenApplication(launchProperty: UInt32(property))
      lifecycle.didFinishLaunching()
      XCTAssertEqual(lifecycle.settingsRequestID, 0)

      lifecycle.handleReopen()
      XCTAssertEqual(lifecycle.settingsRequestID, 1)
      lifecycle.handleReopen()
      XCTAssertEqual(lifecycle.settingsRequestID, 2)
    }
  }

  func testDirectExecutableLaunchWithoutAnAppleEventStillRequestsSettings() {
    let lifecycle = ApplicationLifecycle()

    lifecycle.didFinishLaunching()

    XCTAssertEqual(lifecycle.settingsRequestID, 1)
  }

  func testUnrecognizedLaunchPropertyDoesNotLockUserOutOfSettings() {
    let lifecycle = ApplicationLifecycle()

    lifecycle.handleOpenApplication(launchProperty: 0)
    lifecycle.didFinishLaunching()

    XCTAssertEqual(lifecycle.settingsRequestID, 1)
  }
}
