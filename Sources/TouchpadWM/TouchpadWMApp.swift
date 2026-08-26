import AppKit
import SwiftUI

@main
struct TouchpadWMApp: App {
  @Environment(\.scenePhase) private var scenePhase
  @State private var state: AppState
  @State private var appRules: AppRulesController
  @State private var keyboardMonitor = KeyboardEventMonitor()
  @State private var overlay = SwitcherOverlayPanelController()
  @State private var switcherCoordinator: SwitcherGestureCoordinator

  init() {
    NSApplication.shared.setActivationPolicy(.accessory)
    // A one-time warm-up activation. Without ever activating once, an .accessory-policy app's
    // NSPanel windows (the switcher overlay) can silently fail to actually order to the front
    // on their first show, even though orderFrontRegardless() reports success -- a known AppKit
    // quirk for background/accessory apps that have never been made the active app. This does
    // not conflict with the overlay panel's own .nonactivatingPanel behavior: that governs
    // whether opening the switcher steals focus on each gesture, not this unrelated one-time
    // startup step, and activating a windowless accessory app has no visible effect.
    NSApp.activate(ignoringOtherApps: true)
    let windowManagement = WindowManagementController(service: AccessibilityWindowService())
    let appRules = AppRulesController(windowManagement: windowManagement)
    let overlay = SwitcherOverlayPanelController()
    let switcherController = SwitcherController(windowManaging: windowManagement)
    _state = State(initialValue: AppState(windowManagement: windowManagement))
    _appRules = State(initialValue: appRules)
    _overlay = State(initialValue: overlay)
    let switcherCoordinator = SwitcherGestureCoordinator(
      switcherController: switcherController, overlay: overlay)
    _switcherCoordinator = State(initialValue: switcherCoordinator)

    // Started unconditionally here rather than from the scenePhase onChange below: for an
    // .accessory-policy app, scenePhase reaching .active depends on a real activation transition
    // happening at some point after launch (e.g. opening Settings). Relying on that onChange to
    // start the trackpad bridge meant the switcher gesture silently did nothing
    // until the user happened to trigger one -- the gesture and its keyboard modifiers need no
    // app activation to function, so they start as soon as the app object exists.
    keyboardMonitor.onEscape = { switcherCoordinator.cancelOpenSession() }
    keyboardMonitor.rightOptionDidChange = { isPressed in
      switcherCoordinator.isRightOptionPressed = isPressed
    }
    switcherCoordinator.start()
  }

  var body: some Scene {
    MenuBarExtra("Touchpad WM", systemImage: "hand.draw") {
      StatusMenuView(state: state, keyboardMonitor: keyboardMonitor)
    }
    Settings {
      SettingsView(state: state, appRules: appRules)
    }
    .onChange(of: scenePhase) { _, phase in
      guard phase == .active else {
        return
      }
      state.refreshAccessibilityPermission()
    }
    .onChange(of: state.accessibilityPermission) { _, permission in
      if permission == .available {
        // ScrollEventSuppressor's CGEventTap (created from switcherCoordinator.start() at launch)
        // silently fails to create its tap if the process was not yet Accessibility-trusted at
        // that moment -- which, now that trust is requested asynchronously at launch (see
        // AppState.init()), is the common case on a first run. start() no-ops once the tap
        // already exists, so retrying here is exactly the same "start once trust exists" pattern
        // keyboardMonitor already uses below for Input Monitoring.
        switcherCoordinator.start()
      }
    }
    .onChange(of: state.inputMonitoringPermission) { _, permission in
      if permission == .available {
        keyboardMonitor.start(
          permission: { state.accessibilityPermission },
          perform: state.performLayoutCommand)
      }
    }
  }
}

private struct StatusMenuView: View {
  @Environment(\.openSettings) private var openSettings

  let state: AppState
  let keyboardMonitor: KeyboardEventMonitor

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
    Text(
      state.inputMonitoringPermission == .available
        ? "Input Monitoring granted" : "Input Monitoring required for keyboard shortcuts")
    if state.inputMonitoringPermission == .unavailable {
      Button("Enable Input Monitoring") {
        NSApp.activate(ignoringOtherApps: true)
        DispatchQueue.main.async {
          state.requestInputMonitoringAccess()
        }
      }
    }
    Divider()
    layoutButton("Left half", command: .leftHalf)
    layoutButton("Right half", command: .rightHalf)
    layoutButton("Left 75%", command: .leftThreeQuarters)
    layoutButton("Right 25%", command: .rightQuarter)
    layoutButton("Top-right 25%", command: .topRightQuarter)
    layoutButton("Bottom-right 25%", command: .bottomRightQuarter)
    layoutButton("Master stack", command: .masterStack)
    if !state.windowManagementStatus.isEmpty {
      Text(state.windowManagementStatus)
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
    .onAppear {
      state.refreshAccessibilityPermission()
      if state.inputMonitoringPermission == .available {
        keyboardMonitor.start(
          permission: { state.accessibilityPermission },
          perform: state.performLayoutCommand)
      }
    }
  }

  private func layoutButton(_ title: String, command: LayoutCommand) -> some View {
    Button(title) {
      state.performLayoutCommand(command)
    }
    .disabled(state.accessibilityPermission == .unavailable)
  }
}

private struct SettingsView: View {
  let state: AppState
  let appRules: AppRulesController
  @State private var appSearch = ""
  @State private var iconCache = ApplicationIconCache()

  var body: some View {
    List {
      Section("Accessibility") {
        Text(state.accessibilityPermission == .available ? "Access granted" : "Access required")
        Text("Window-management commands require Accessibility access.")
        Button("Open Accessibility Settings") {
          state.openAccessibilitySettings()
        }
        Button("Refresh Accessibility Status") {
          state.refreshAccessibilityPermission()
        }
      }
      Section("Input Monitoring") {
        Text(
          state.inputMonitoringPermission == .available
            ? "Access granted" : "Keyboard shortcuts require access.")
        Button("Enable Input Monitoring") {
          NSApp.activate(ignoringOtherApps: true)
          DispatchQueue.main.async {
            state.requestInputMonitoringAccess()
          }
        }
      }
      Section("App Rules") {
        TextField("Search applications", text: $appSearch)
        ForEach(appRules.applications(matching: appSearch)) { application in
          HStack(alignment: .top) {
            Image(nsImage: iconCache.icon(for: application))
              .resizable()
              .frame(width: 32, height: 32)
            VStack(alignment: .leading) {
              Text(application.name)
              Text(application.bundleIdentifier)
                .font(.caption)
                .foregroundStyle(.secondary)
              Toggle("Include in Switcher", isOn: switcherBinding(for: application))
              Toggle("Manage Layout", isOn: layoutBinding(for: application))
            }
          }
        }
      }
    }
    .frame(width: 420, height: 600)
    .contentMargins(8, for: .scrollContent)
    .onAppear {
      appRules.refresh()
    }
  }

  private func switcherBinding(for application: InstalledApplication) -> Binding<Bool> {
    Binding(
      get: { appRules.rule(for: application.bundleIdentifier).includeInSwitcher },
      set: { includeInSwitcher in
        var rule = appRules.rule(for: application.bundleIdentifier)
        rule.includeInSwitcher = includeInSwitcher
        appRules.setRule(rule, for: application.bundleIdentifier)
      })
  }

  private func layoutBinding(for application: InstalledApplication) -> Binding<Bool> {
    Binding(
      get: { appRules.rule(for: application.bundleIdentifier).manageLayout },
      set: { manageLayout in
        var rule = appRules.rule(for: application.bundleIdentifier)
        rule.manageLayout = manageLayout
        appRules.setRule(rule, for: application.bundleIdentifier)
      })
  }
}

final class KeyboardEventMonitor {
  private var eventTap: CFMachPort?
  private var eventTapSource: CFRunLoopSource?
  private var router = KeyboardCommandRouter()
  private var permission: (() -> AccessibilityPermissionState)?
  private var perform: ((LayoutCommand) -> Void)?
  private var rightOptionIsPressed = false

  var onEscape: (() -> Void)?
  var rightOptionDidChange: ((Bool) -> Void)?

  func start(
    permission: @escaping () -> AccessibilityPermissionState,
    perform: @escaping (LayoutCommand) -> Void
  ) {
    guard eventTap == nil else {
      return
    }

    self.permission = permission
    self.perform = perform
    let eventMask =
      (CGEventMask(1) << CGEventType.flagsChanged.rawValue)
      | (CGEventMask(1) << CGEventType.keyDown.rawValue)
    eventTap = CGEvent.tapCreate(
      tap: .cgSessionEventTap,
      place: .headInsertEventTap,
      options: .defaultTap,
      eventsOfInterest: eventMask,
      callback: keyboardEventTapCallback,
      userInfo: Unmanaged.passUnretained(self).toOpaque())

    guard let eventTap else {
      return
    }
    eventTapSource = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, eventTap, 0)
    guard let eventTapSource else {
      self.eventTap = nil
      return
    }
    CFRunLoopAddSource(CFRunLoopGetMain(), eventTapSource, .commonModes)
    CGEvent.tapEnable(tap: eventTap, enable: true)
  }

  fileprivate static func handle(
    _ proxy: CGEventTapProxy,
    _ type: CGEventType,
    _ event: CGEvent,
    _ userInfo: UnsafeMutableRawPointer?
  ) -> Unmanaged<CGEvent>? {
    guard let userInfo else {
      return Unmanaged.passUnretained(event)
    }
    let monitor = Unmanaged<KeyboardEventMonitor>.fromOpaque(userInfo).takeUnretainedValue()
    if type == .tapDisabledByTimeout || type == .tapDisabledByUserInput {
      if let eventTap = monitor.eventTap {
        CGEvent.tapEnable(tap: eventTap, enable: true)
      }
      return Unmanaged.passUnretained(event)
    }

    let keyCode = UInt16(event.getIntegerValueField(.keyboardEventKeycode))
    if type == .flagsChanged, keyCode == 61 {
      monitor.rightOptionIsPressed.toggle()
      monitor.rightOptionDidChange?(monitor.rightOptionIsPressed)
    }
    if type == .keyDown, keyCode == 53 {
      monitor.onEscape?()
    }

    guard let input = input(from: type, event: event),
      let permission = monitor.permission,
      let perform = monitor.perform
    else {
      return Unmanaged.passUnretained(event)
    }
    let didDispatch = monitor.router.consume(
      input, permission: permission(), perform: perform)
    return didDispatch ? nil : Unmanaged.passUnretained(event)
  }

  private static func input(from type: CGEventType, event: CGEvent) -> KeyboardInput? {
    let keyCode = UInt16(event.getIntegerValueField(.keyboardEventKeycode))
    return switch type {
    case .flagsChanged:
      .flagsChanged(keyCode: keyCode)
    case .keyDown:
      .keyDown(keyCode: keyCode, shiftIsPressed: event.flags.contains(.maskShift))
    default:
      nil
    }
  }
}

private func keyboardEventTapCallback(
  _ proxy: CGEventTapProxy,
  _ type: CGEventType,
  _ event: CGEvent,
  _ userInfo: UnsafeMutableRawPointer?
) -> Unmanaged<CGEvent>? {
  KeyboardEventMonitor.handle(proxy, type, event, userInfo)
}
