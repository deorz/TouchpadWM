import CoreGraphics
import XCTest

@testable import TouchpadWM

final class WindowPickerRowPresentationTests: XCTestCase {
  func testEmptyWindowTitleUsesTheApplicationNameAsTheOnlyLabel() {
    let presentation = WindowPickerRowPresentation(window: makeWindow(title: ""))

    XCTAssertEqual(presentation.primaryTitle, "Editor")
    XCTAssertNil(presentation.secondaryTitle)
  }

  func testDistinctWindowTitleKeepsTheApplicationNameAsSecondaryLabel() {
    let presentation = WindowPickerRowPresentation(window: makeWindow(title: "Quarterly plan"))

    XCTAssertEqual(presentation.primaryTitle, "Quarterly plan")
    XCTAssertEqual(presentation.secondaryTitle, "Editor")
  }

  func testWindowTitleMatchingApplicationNameDoesNotRepeatTheLabel() {
    let presentation = WindowPickerRowPresentation(window: makeWindow(title: "Editor"))

    XCTAssertEqual(presentation.primaryTitle, "Editor")
    XCTAssertNil(presentation.secondaryTitle)
  }

  private func makeWindow(title: String) -> CataloguedWindow {
    CataloguedWindow(
      id: WindowID(processIdentifier: 1, windowNumber: 1),
      bundleIdentifier: "com.example.editor",
      applicationName: "Editor",
      title: title,
      role: .normal,
      isMinimized: false,
      visibleFrame: CGRect(x: 0, y: 0, width: 1000, height: 800))
  }
}
