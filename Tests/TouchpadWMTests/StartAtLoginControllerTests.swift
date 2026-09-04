import XCTest

@testable import TouchpadWM

@MainActor
final class StartAtLoginControllerTests: XCTestCase {
  func testEnablingStartAtLoginUpdatesTheVisibleState() {
    let controller = StartAtLoginController(service: InMemoryLoginItemService(isEnabled: false))

    controller.setEnabled(true)

    XCTAssertTrue(controller.isEnabled)
    XCTAssertNil(controller.errorMessage)
  }

  func testFailedChangeKeepsTheCurrentStateAndExposesAnError() {
    let controller = StartAtLoginController(
      service: InMemoryLoginItemService(isEnabled: false, failure: LoginItemError.unavailable))

    controller.setEnabled(true)

    XCTAssertFalse(controller.isEnabled)
    XCTAssertEqual(controller.errorMessage, "Could not update Start at login.")
  }
}

private enum LoginItemError: LocalizedError {
  case unavailable

  var errorDescription: String? {
    "The system login-item service is unavailable."
  }
}

private final class InMemoryLoginItemService: LoginItemManaging {
  private(set) var isEnabled: Bool
  private let failure: (any Error)?

  init(isEnabled: Bool, failure: (any Error)? = nil) {
    self.isEnabled = isEnabled
    self.failure = failure
  }

  func setEnabled(_ isEnabled: Bool) throws {
    if let failure {
      throw failure
    }
    self.isEnabled = isEnabled
  }
}
