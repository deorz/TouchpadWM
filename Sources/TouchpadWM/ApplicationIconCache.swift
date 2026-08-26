import AppKit

@MainActor
final class ApplicationIconCache {
  typealias URLResolving = (String) -> URL?
  typealias IconLoading = (String) -> NSImage

  private let resolveURL: URLResolving
  private let loadIcon: IconLoading
  private var icons: [String: NSImage] = [:]

  init(
    resolveURL: @escaping URLResolving = { bundleIdentifier in
      NSWorkspace.shared.urlForApplication(withBundleIdentifier: bundleIdentifier)
    },
    loadIcon: @escaping IconLoading = { NSWorkspace.shared.icon(forFile: $0) }
  ) {
    self.resolveURL = resolveURL
    self.loadIcon = loadIcon
  }

  func icon(for application: InstalledApplication) -> NSImage {
    icon(forBundleIdentifier: application.bundleIdentifier, filePath: application.url.path)
  }

  func icon(forBundleIdentifier bundleIdentifier: String) -> NSImage {
    if let icon = icons[bundleIdentifier] {
      return icon
    }
    guard let url = resolveURL(bundleIdentifier) else {
      return NSImage()
    }
    return icon(forBundleIdentifier: bundleIdentifier, filePath: url.path)
  }

  private func icon(forBundleIdentifier bundleIdentifier: String, filePath: String) -> NSImage {
    if let icon = icons[bundleIdentifier] {
      return icon
    }
    let icon = loadIcon(filePath)
    icons[bundleIdentifier] = icon
    return icon
  }
}
