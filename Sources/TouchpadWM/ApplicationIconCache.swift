import AppKit

@MainActor
final class ApplicationIconCache {
  typealias IconLoading = (String) -> NSImage

  private let loadIcon: IconLoading
  private var icons: [String: NSImage] = [:]

  init(loadIcon: @escaping IconLoading = { NSWorkspace.shared.icon(forFile: $0) }) {
    self.loadIcon = loadIcon
  }

  func icon(for application: InstalledApplication) -> NSImage {
    if let icon = icons[application.bundleIdentifier] {
      return icon
    }

    let icon = loadIcon(application.url.path)
    icons[application.bundleIdentifier] = icon
    return icon
  }
}
