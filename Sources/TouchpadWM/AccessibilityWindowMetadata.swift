struct AccessibilityWindowMetadata {
  static func role(role: String?, subrole: String?) -> WindowRole {
    if role == "AXSheet" { return .sheet }
    if role == "AXDialog" { return .dialog }
    if role == "AXPopover" { return .popover }
    if subrole == "AXFloatingWindow" || subrole == "AXUtilityWindow" { return .floating }
    return role == "AXWindow" ? .normal : .unknown
  }
}
