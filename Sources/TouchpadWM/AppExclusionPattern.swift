import Foundation

struct AppExclusionPattern: Codable, Equatable, Identifiable {
  let id: UUID
  let pattern: String

  init?(pattern: String) {
    guard
      !pattern.isEmpty,
      (try? NSRegularExpression(pattern: pattern)) != nil
    else {
      return nil
    }

    self.id = UUID()
    self.pattern = pattern
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
