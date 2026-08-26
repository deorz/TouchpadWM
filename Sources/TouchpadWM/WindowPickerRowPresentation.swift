struct WindowPickerRowPresentation {
  let primaryTitle: String
  let secondaryTitle: String?

  init(window: CataloguedWindow) {
    primaryTitle = window.title.isEmpty ? window.applicationName : window.title
    secondaryTitle =
      window.title.isEmpty || window.title == window.applicationName
      ? nil : window.applicationName
  }
}
