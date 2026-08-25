import AppKit
import SwiftUI

@main
struct TouchpadWMApp: App {
  @Environment(\.scenePhase) private var scenePhase
  @State private var state: AppState
  @State private var keyboardMonitor = KeyboardEventMonitor()
  @State private var overlay = SwitcherOverlayPanelController()
  @State private var switcherCoordinator: SwitcherGestureCoordinator

  init() {
    NSApplication.shared.setActivationPolicy(.accessory)
    let windowManagement = WindowManagementController(service: AccessibilityWindowService())
    let overlay = SwitcherOverlayPanelController()
    let switcherController = SwitcherController(windowManaging: windowManagement)
    _state = State(initialValue: AppState(windowManagement: windowManagement))
    _overlay = State(initialValue: overlay)
    _switcherCoordinator = State(
      initialValue: SwitcherGestureCoordinator(
        switcherController: switcherController, overlay: overlay))
  }

  var body: some Scene {
    MenuBarExtra("Touchpad WM", systemImage: "hand.draw") {
      StatusMenuView(state: state, keyboardMonitor: keyboardMonitor)
    }
    Settings {
      SettingsView(state: state)
    }
    .onChange(of: scenePhase) { _, phase in
      guard phase == .active else {
        return
      }
      state.refreshAccessibilityPermission()
      keyboardMonitor.onEscape = { switcherCoordinator.cancelOpenSession() }
      keyboardMonitor.rightOptionDidChange = { isPressed in
        switcherCoordinator.isRightOptionPressed = isPressed
      }
      switcherCoordinator.start()
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

  var body: some View {
    Form {
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
        Text("App Rules will appear here in a later milestone.")
      }
    }
    .frame(width: 360)
    .padding()
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
