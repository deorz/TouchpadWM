import Foundation

struct AppExclusionPattern: Codable, Equatable, Identifiable {
  let id: UUID
  var pattern: String
  let sourceBundleIdentifier: String?

  init?(
    id: UUID = UUID(),
    pattern: String,
    sourceBundleIdentifier: String? = nil
  ) {
    guard
      !pattern.isEmpty,
      (try? NSRegularExpression(pattern: pattern)) != nil
    else {
      return nil
    }

    self.id = id
    self.pattern = pattern
    self.sourceBundleIdentifier = sourceBundleIdentifier
  }

  init?(exactBundleIdentifier: String) {
    guard !exactBundleIdentifier.isEmpty else {
      return nil
    }

    self.init(
      pattern: "^\(NSRegularExpression.escapedPattern(for: exactBundleIdentifier))$",
      sourceBundleIdentifier: exactBundleIdentifier)
  }

  var isValid: Bool {
    !pattern.isEmpty && (try? NSRegularExpression(pattern: pattern)) != nil
  }

  func matches(_ bundleIdentifier: String) -> Bool {
    guard
      isValid,
      let regex = try? NSRegularExpression(
        pattern: pattern,
        options: [.caseInsensitive])
    else {
      return false
    }

    let range = NSRange(location: 0, length: bundleIdentifier.utf16.count)
    return regex.firstMatch(in: bundleIdentifier, options: [], range: range) != nil
  }
}
