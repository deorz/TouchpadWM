import CoreGraphics

enum PickerWindowEligibility {
  static func shouldInclude(
    bundleIdentifier: String?,
    windowLayer: Int,
    frame: CGRect
  ) -> Bool {
    bundleIdentifier != "com.apple.universalcontrol"
      && windowLayer == 0
      && frame.width > 100
      && frame.height > 50
  }
}
