import Foundation

struct InstalledApplication: Equatable, Identifiable {
  let bundleIdentifier: String
  let name: String
  let url: URL

  var id: String { bundleIdentifier }
}

protocol ApplicationInventorying {
  func installedApplications() -> [InstalledApplication]
}

struct ApplicationInventory: ApplicationInventorying {
  static let finderURL = URL(filePath: "/System/Library/CoreServices/Finder.app")
  static let standardRoots = [
    URL(filePath: "/Applications"),
    FileManager.default.homeDirectoryForCurrentUser.appending(path: "Applications"),
    URL(filePath: "/System/Applications"),
    URL(filePath: "/Library/Application Support"),
  ]

  private let roots: [URL]
  private let additionalApplicationURLs: [URL]

  init(
    roots: [URL] = ApplicationInventory.standardRoots,
    additionalApplicationURLs: [URL] = [ApplicationInventory.finderURL]
  ) {
    self.roots = roots
    self.additionalApplicationURLs = additionalApplicationURLs
  }

  func installedApplications() -> [InstalledApplication] {
    let candidates =
      roots.flatMap(applications(in:))
      + additionalApplicationURLs.compactMap(application(at:))
    let ordered = candidates.sorted { $0.url.path < $1.url.path }
    var byIdentifier: [String: InstalledApplication] = [:]
    for application in ordered where byIdentifier[application.bundleIdentifier] == nil {
      byIdentifier[application.bundleIdentifier] = application
    }
    return byIdentifier.values.sorted {
      let comparison = $0.name.localizedCaseInsensitiveCompare($1.name)
      return comparison == .orderedSame
        ? $0.bundleIdentifier < $1.bundleIdentifier
        : comparison == .orderedAscending
    }
  }

  private func applications(in root: URL) -> [InstalledApplication] {
    guard
      let enumerator = FileManager.default.enumerator(
        at: root,
        includingPropertiesForKeys: nil,
        options: [.skipsHiddenFiles, .skipsPackageDescendants])
    else {
      return []
    }

    return enumerator.compactMap { element in
      guard let url = element as? URL else {
        return nil
      }
      return application(at: url)
    }
  }

  private func application(at url: URL) -> InstalledApplication? {
    guard
      url.pathExtension == "app",
      let bundle = Bundle(url: url),
      let bundleIdentifier = bundle.bundleIdentifier
    else {
      return nil
    }
    let name =
      (bundle.object(forInfoDictionaryKey: "CFBundleDisplayName") as? String)
      ?? (bundle.object(forInfoDictionaryKey: "CFBundleName") as? String)
      ?? url.deletingPathExtension().lastPathComponent
    return InstalledApplication(bundleIdentifier: bundleIdentifier, name: name, url: url)
  }
}
