import CoreGraphics

enum PickerWindowEligibility {
  static func shouldInclude(
    bundleIdentifier: String?,
    windowLayer: Int,
    frame: CGRect,
    role: WindowRole
  ) -> Bool {
    bundleIdentifier != "com.apple.universalcontrol"
      && !isChromeFloatingWindow(bundleIdentifier: bundleIdentifier, role: role)
      && windowLayer == 0
      && frame.width > 100
      && frame.height > 50
  }

  private static func isChromeFloatingWindow(bundleIdentifier: String?, role: WindowRole) -> Bool {
    bundleIdentifier == "com.google.Chrome" && role == .floating
  }
}
