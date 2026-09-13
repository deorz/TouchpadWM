import AppKit
import SwiftUI

@main
struct TouchpadWMApp: App {
  @Environment(\.scenePhase) private var scenePhase
  @NSApplicationDelegateAdaptor(TouchpadWMAppDelegate.self) private var appDelegate
  @State private var state: AppState
  @State private var applicationPreferences: ApplicationPreferences
  @State private var appRules: AppRulesController
  @State private var gesturePreferences: GesturePreferences
  @State private var startAtLogin: StartAtLoginController
  @State private var overlay: SwitcherOverlayPanelController
  @State private var switcherCoordinator: SwitcherGestureCoordinator
  @State private var pickerStartup: PickerStartupGate

  init() {
    NSApplication.shared.setActivationPolicy(.accessory)

    let windowPicker = WindowPickerController(service: AccessibilityWindowService())
    let appRules = AppRulesController(windowPicker: windowPicker)
    let gesturePreferences = GesturePreferences()
    let startAtLogin = StartAtLoginController()
    let overlay = SwitcherOverlayPanelController(preferences: gesturePreferences)
    let switcherController = SwitcherController(windowSource: windowPicker)
    let switcherCoordinator = SwitcherGestureCoordinator(
      switcherController: switcherController,
      overlay: overlay,
      preferences: gesturePreferences)
    let appState = AppState(requestTrustOnInit: false)
    let pickerStartup = PickerStartupGate()

    _state = State(initialValue: appState)
    _applicationPreferences = State(initialValue: ApplicationPreferences())
    _appRules = State(initialValue: appRules)
    _gesturePreferences = State(initialValue: gesturePreferences)
    _startAtLogin = State(initialValue: startAtLogin)
    _overlay = State(initialValue: overlay)
    _switcherCoordinator = State(initialValue: switcherCoordinator)
    _pickerStartup = State(initialValue: pickerStartup)
    pickerStartup.startIfPermitted(appState.accessibilityPermission) {
      switcherCoordinator.start()
    }
  }

  /// A monochrome template image: only its alpha channel is used, so AppKit tints it
  /// automatically to match the light or dark menu bar. Embedded as base64 (see
  /// `MenuBarIconData`) rather than an SPM resource bundle, which has no reliable location
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
    MenuBarExtra(isInserted: menuBarIconBinding) {
      StatusMenuView(state: state)
    } label: {
      Image(nsImage: Self.menuBarIcon)
    }
    SettingsScene(lifecycle: appDelegate.lifecycle) {
      SettingsView(
        state: state,
        appRules: appRules,
        gesturePreferences: gesturePreferences,
        startAtLogin: startAtLogin,
        applicationPreferences: applicationPreferences)
    }
    .onChange(of: scenePhase) { _, phase in
      guard phase == .active else {
        return
      }
      state.refreshAccessibilityPermission()
    }
    .onChange(of: state.accessibilityPermission) { _, permission in
      pickerStartup.startIfPermitted(permission) {
        switcherCoordinator.start()
      }
    }
  }

  private var menuBarIconBinding: Binding<Bool> {
    Binding(
      get: { applicationPreferences.showMenuBarIcon },
      set: { applicationPreferences.showMenuBarIcon = $0 })
  }
}

/// Keep a window scene even with no menu extra, so hiding the icon never turns this
/// into a menu-extra-only app that SwiftUI can terminate when its last extra is removed.
private struct SettingsScene<Content: View>: Scene {
  @Environment(\.openWindow) private var openWindow
  // Explicitly observe requests here: the delegate adaptor alone does not invalidate a scene.
  @ObservedObject var lifecycle: ApplicationLifecycle
  @ViewBuilder var content: () -> Content

  var body: some Scene {
    Window("Settings", id: "settings", content: content)
      .defaultSize(width: 880, height: 560)
      .defaultLaunchBehavior(.suppressed)
      .restorationBehavior(.disabled)
      .onChange(of: lifecycle.settingsRequestID, initial: true) { _, requestID in
        guard requestID > 0 else { return }
        openWindow(id: "settings")
        NSApp.activate(ignoringOtherApps: true)
      }
  }
}

@MainActor
final class TouchpadWMAppDelegate: NSObject, NSApplicationDelegate {
  let lifecycle = ApplicationLifecycle()

  func applicationWillFinishLaunching(_ notification: Notification) {
    // Inspect the actual open event rather than currentAppleEvent in a later callback,
    // where the login-item parameter may no longer be available.
    NSAppleEventManager.shared().setEventHandler(
      self,
      andSelector: #selector(handleOpenApplication(_:withReplyEvent:)),
      forEventClass: AEEventClass(kCoreEventClass),
      andEventID: AEEventID(kAEOpenApplication))
  }

  @objc func handleOpenApplication(
    _ event: NSAppleEventDescriptor,
    withReplyEvent reply: NSAppleEventDescriptor
  ) {
    lifecycle.handleOpenApplication(
      launchProperty: event.paramDescriptor(forKeyword: AEKeyword(keyAEPropData))?.enumCodeValue)
  }

  func applicationDidFinishLaunching(_ notification: Notification) {
    lifecycle.didFinishLaunching()
  }

  func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows: Bool) -> Bool {
    lifecycle.handleReopen()
    return false
  }

  func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
    false
  }
}

private struct StatusMenuView: View {
  @Environment(\.openWindow) private var openWindow

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
    Button("Settings…") {
      NSApp.activate(ignoringOtherApps: true)
      DispatchQueue.main.async {
        openWindow(id: "settings")
      }
    }
    Button("Quit Touchpad WM") {
      NSApplication.shared.terminate(nil)
    }
  }
}
