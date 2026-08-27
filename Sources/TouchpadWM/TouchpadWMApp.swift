import AppKit
import SwiftUI

@main
struct TouchpadWMApp: App {
  @Environment(\.scenePhase) private var scenePhase
  @State private var state: AppState
  @State private var appRules: AppRulesController
  @State private var overlay: SwitcherOverlayPanelController
  @State private var switcherCoordinator: SwitcherGestureCoordinator

  init() {
    NSApplication.shared.setActivationPolicy(.accessory)
    NSApp.activate(ignoringOtherApps: true)

    let windowPicker = WindowPickerController(service: AccessibilityWindowService())
    let appRules = AppRulesController(windowPicker: windowPicker)
    let overlay = SwitcherOverlayPanelController()
    let switcherController = SwitcherController(windowSource: windowPicker)
    let switcherCoordinator = SwitcherGestureCoordinator(
      switcherController: switcherController, overlay: overlay)

    _state = State(initialValue: AppState())
    _appRules = State(initialValue: appRules)
    _overlay = State(initialValue: overlay)
    _switcherCoordinator = State(initialValue: switcherCoordinator)
    switcherCoordinator.start()
  }

  /// A monochrome template image: only its alpha channel is used, so AppKit tints it
  /// automatically to match the light or dark menu bar. Embedded as base64 (see
  /// MenuBarIconData) rather than an SPM resource bundle, which has no reliable location
  /// inside a codesigned .app.
  private static let menuBarIcon: NSImage = {
    guard let data = Data(base64Encoded: MenuBarIconData.pdfBase64),
      let image = NSImage(data: data)
    else {
      return NSImage(systemSymbolName: "hand.draw", accessibilityDescription: "Touchpad WM")
        ?? NSImage()
    }
    image.isTemplate = true
    return image
  }()

  var body: some Scene {
    MenuBarExtra {
      StatusMenuView(state: state)
    } label: {
      Image(nsImage: Self.menuBarIcon)
    }
    Settings {
      SettingsView(state: state, appRules: appRules)
    }
    .defaultSize(width: 860, height: 620)
    .onChange(of: scenePhase) { _, phase in
      guard phase == .active else {
        return
      }
      state.refreshAccessibilityPermission()
    }
    .onChange(of: state.accessibilityPermission) { _, permission in
      if permission == .available {
        switcherCoordinator.start()
      }
    }
  }
}

private struct StatusMenuView: View {
  @Environment(\.openSettings) private var openSettings

  let state: AppState

  var body: some View {
    Text(
      state.accessibilityPermission == .available
        ? "Accessibility access granted" : "Accessibility access required")
    if state.accessibilityPermission == .unavailable {
      Button("Open Accessibility Settings") {
        state.openAccessibilitySettings()
      }
    }
    Button("Refresh Accessibility Status") {
      state.refreshAccessibilityPermission()
    }
    Divider()
    Button("Settings") {
      NSApp.activate(ignoringOtherApps: true)
      DispatchQueue.main.async {
        openSettings()
      }
    }
    Button("Quit Touchpad WM") {
      NSApplication.shared.terminate(nil)
    }
  }
}
