import CoreGraphics
import XCTest

@testable import TouchpadWM

final class WindowCatalogueTests: XCTestCase {
  func testFinderCanBeIncludedInPicker() {
    var catalogue = WindowCatalogue()
    catalogue.replaceWindows([finderWindow, editorWindow])
    catalogue.setRule(.included, for: finderWindow.bundleIdentifier)

    XCTAssertEqual(catalogue.windowsForSwitcher.map(\.id), [finderWindow.id, editorWindow.id])
  }

  func testPickerIncludesAllWindowRoles() {
    var catalogue = WindowCatalogue()
    catalogue.replaceWindows([normalWindow, utilityWindow, sheetWindow, unknownRoleWindow])

    XCTAssertEqual(
      catalogue.windowsForSwitcher.map(\.id),
      [normalWindow.id, utilityWindow.id, sheetWindow.id, unknownRoleWindow.id])
  }

  func testPickerExclusionHidesOnlyTheExcludedApplication() {
    var catalogue = WindowCatalogue()
    catalogue.replaceWindows([editorWindow, normalWindow])
    catalogue.setRule(.init(includeInSwitcher: false), for: editorWindow.bundleIdentifier)

    XCTAssertEqual(catalogue.windowsForSwitcher.map(\.id), [normalWindow.id])
  }

  func testPickerPreservesApplicationNameForPresentation() {
    let window = CataloguedWindow(
      id: WindowID(processIdentifier: 1, windowNumber: 20),
      bundleIdentifier: "com.example.editor",
      applicationName: "Editor",
      title: "Document",
      role: .normal,
      isMinimized: false,
      visibleFrame: CGRect(x: 0, y: 0, width: 1000, height: 800))
    var catalogue = WindowCatalogue()
    catalogue.replaceWindows([window])

    XCTAssertEqual(catalogue.windowsForSwitcher.first?.applicationName, "Editor")
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
      applicationName: "Example App",
      title: "Window \(id)",
      role: role,
      isMinimized: false,
      visibleFrame: CGRect(x: 0, y: 0, width: 1000, height: 800))
  }
}
