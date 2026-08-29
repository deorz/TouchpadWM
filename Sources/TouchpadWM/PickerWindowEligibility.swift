import CoreGraphics

enum PickerWindowEligibility {
  static func shouldInclude(
    bundleIdentifier: String?,
    windowLayer: Int,
    frame: CGRect,
    accessibilitySubrole: String?
  ) -> Bool {
    bundleIdentifier != "com.apple.universalcontrol"
      && AccessibilityWindowMetadata.isSwitcherCandidateSubrole(accessibilitySubrole)
      && windowLayer == 0
      && frame.width > 100
      && frame.height > 50
  }
}
