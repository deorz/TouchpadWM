import CoreGraphics
import XCTest

@testable import TouchpadWM

final class WindowCatalogueTests: XCTestCase {
  func testFinderIsExcludedFromBothCollectionsByDefault() {
    var catalogue = WindowCatalogue()
    catalogue.replaceWindows([finderWindow, editorWindow])

    XCTAssertEqual(catalogue.windowsForSwitcher.map(\.id), [editorWindow.id])
    XCTAssertEqual(catalogue.managedWindows.map(\.id), [editorWindow.id])
  }

  func testUtilityAndSheetWindowsRemainSwitchableButAreNotManaged() {
    var catalogue = WindowCatalogue()
    catalogue.replaceWindows([normalWindow, utilityWindow, sheetWindow])

    XCTAssertEqual(
      catalogue.windowsForSwitcher.map(\.id), [normalWindow.id, utilityWindow.id, sheetWindow.id])
    XCTAssertEqual(catalogue.managedWindows.map(\.id), [normalWindow.id])
  }

  func testUnknownRoleWindowsRemainManaged() {
    var catalogue = WindowCatalogue()
    catalogue.replaceWindows([unknownRoleWindow])

    XCTAssertEqual(catalogue.managedWindows.map(\.id), [unknownRoleWindow.id])
  }

  func testAppRulesFilterSwitcherAndLayoutIndependently() {
    var catalogue = WindowCatalogue()
    catalogue.replaceWindows([editorWindow])
    catalogue.setRule(
      .init(includeInSwitcher: false, manageLayout: true), for: editorWindow.bundleIdentifier)

    XCTAssertTrue(catalogue.windowsForSwitcher.isEmpty)
    XCTAssertEqual(catalogue.managedWindows.map(\.id), [editorWindow.id])
  }

  func testMarkingFocusMovesOnlyThatEligibleWindowToFrontOfMRUOrder() {
    var catalogue = WindowCatalogue()
    catalogue.replaceWindows([oldWindow, currentWindow])
    catalogue.markFocused(oldWindow.id)

    XCTAssertEqual(catalogue.windowsForSwitcher.map(\.id), [oldWindow.id, currentWindow.id])
  }

  private var finderWindow: CataloguedWindow {
    window(id: 1, bundleIdentifier: "com.apple.finder")
  }

  private var editorWindow: CataloguedWindow {
    window(id: 2, bundleIdentifier: "com.example.editor")
  }

  private var normalWindow: CataloguedWindow {
    window(id: 3, bundleIdentifier: "com.example.normal")
  }

  private var utilityWindow: CataloguedWindow {
    window(id: 4, bundleIdentifier: "com.example.utility", role: .utility)
  }

  private var sheetWindow: CataloguedWindow {
    window(id: 5, bundleIdentifier: "com.example.sheet", role: .sheet)
  }

  private var unknownRoleWindow: CataloguedWindow {
    window(id: 8, bundleIdentifier: "com.example.unknown", role: .unknown)
  }

  private var oldWindow: CataloguedWindow {
    window(id: 6, bundleIdentifier: "com.example.old")
  }

  private var currentWindow: CataloguedWindow {
    window(id: 7, bundleIdentifier: "com.example.current")
  }

  private func window(id: CGWindowID, bundleIdentifier: String, role: WindowRole = .normal)
    -> CataloguedWindow
  {
    CataloguedWindow(
      id: WindowID(processIdentifier: 1, windowNumber: id),
      bundleIdentifier: bundleIdentifier,
      title: "Window \(id)",
      role: role,
      isMinimized: false,
      visibleFrame: CGRect(x: 0, y: 0, width: 1000, height: 800))
  }
}
