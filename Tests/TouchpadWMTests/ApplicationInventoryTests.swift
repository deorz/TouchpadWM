import Foundation
import XCTest

@testable import TouchpadWM

final class ApplicationInventoryTests: XCTestCase {
  func testInventoryFindsBundlesAcrossRootsAndSortsByName() throws {
    let root = try makeTemporaryDirectory()
    try makeApp(at: root.appending(path: "Zulu.app"), bundleIdentifier: "zulu", name: "Zulu")
    try makeApp(
      at: root.appending(path: "Nested/Alpha.app"), bundleIdentifier: "alpha", name: "Alpha")
    let inventory = ApplicationInventory(roots: [root], additionalApplicationURLs: [])

    XCTAssertEqual(inventory.installedApplications().map(\.name), ["Alpha", "Zulu"])
  }

  func testInventorySkipsMissingIdentifiersAndChoosesOneDeterministicDuplicate() throws {
    let root = try makeTemporaryDirectory()
    let first = root.appending(path: "First")
    let second = root.appending(path: "Second")
    try FileManager.default.createDirectory(at: first, withIntermediateDirectories: true)
    try FileManager.default.createDirectory(at: second, withIntermediateDirectories: true)
    try makeApp(at: first.appending(path: "Editor.app"), bundleIdentifier: "editor", name: "Editor")
    try makeApp(at: second.appending(path: "Other.app"), bundleIdentifier: "editor", name: "Other")
    try makeApp(at: second.appending(path: "Broken.app"), bundleIdentifier: nil, name: "Broken")

    let applications = ApplicationInventory(
      roots: [second, first], additionalApplicationURLs: []
    ).installedApplications()

    XCTAssertEqual(applications.map(\.bundleIdentifier), ["editor"])
    XCTAssertEqual(applications.first?.url.lastPathComponent, "Editor.app")
  }

  func testStandardRootsIncludeSystemApplicationSupport() {
    XCTAssertTrue(
      ApplicationInventory.standardRoots.contains(
        URL(filePath: "/Library/Application Support")))
  }

  func testInventoryIncludesAnExplicitAdditionalApplication() throws {
    let root = try makeTemporaryDirectory()
    let finder = root.appending(path: "Finder.app")
    try makeApp(at: finder, bundleIdentifier: "com.apple.finder", name: "Finder")
    let inventory = ApplicationInventory(roots: [], additionalApplicationURLs: [finder])

    XCTAssertEqual(
      inventory.installedApplications(),
      [InstalledApplication(bundleIdentifier: "com.apple.finder", name: "Finder", url: finder)])
  }

  private func makeTemporaryDirectory() throws -> URL {
    let directory = FileManager.default.temporaryDirectory.appending(path: UUID().uuidString)
    try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
    addTeardownBlock {
      try? FileManager.default.removeItem(at: directory)
    }
    return directory
  }

  private func makeApp(at url: URL, bundleIdentifier: String?, name: String) throws {
    let contents = url.appending(path: "Contents")
    try FileManager.default.createDirectory(at: contents, withIntermediateDirectories: true)
    var values = ["CFBundleName": name]
    if let bundleIdentifier {
      values["CFBundleIdentifier"] = bundleIdentifier
    }
    let data = try PropertyListSerialization.data(
      fromPropertyList: values, format: .xml, options: 0)
    try data.write(to: contents.appending(path: "Info.plist"))
  }
}
