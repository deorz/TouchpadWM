import AppKit
import XCTest

@testable import TouchpadWM

@MainActor
final class ApplicationIconCacheTests: XCTestCase {
  func testRepeatedLookupForAnApplicationLoadsItsIconOnce() {
    let application = InstalledApplication(
      bundleIdentifier: "com.example.editor",
      name: "Editor",
      url: URL(filePath: "/Applications/Editor.app"))
    let expectedIcon = NSImage(size: NSSize(width: 32, height: 32))
    var loadCount = 0
    let cache = ApplicationIconCache(loadIcon: { _ in
      loadCount += 1
      return expectedIcon
    })

    let firstIcon = cache.icon(for: application)
    let secondIcon = cache.icon(for: application)

    XCTAssertTrue(firstIcon === expectedIcon)
    XCTAssertTrue(secondIcon === expectedIcon)
    XCTAssertEqual(loadCount, 1)
  }

  func testBundleIdentifierLookupCachesItsResolvedIcon() {
    let expectedIcon = NSImage(size: NSSize(width: 32, height: 32))
    var resolveCount = 0
    var loadCount = 0
    let cache = ApplicationIconCache(
      resolveURL: { _ in
        resolveCount += 1
        return URL(filePath: "/Applications/Editor.app")
      },
      loadIcon: { _ in
        loadCount += 1
        return expectedIcon
      })

    XCTAssertTrue(cache.icon(forBundleIdentifier: "com.example.editor") === expectedIcon)
    XCTAssertTrue(cache.icon(forBundleIdentifier: "com.example.editor") === expectedIcon)
    XCTAssertEqual(resolveCount, 1)
    XCTAssertEqual(loadCount, 1)
  }
}
