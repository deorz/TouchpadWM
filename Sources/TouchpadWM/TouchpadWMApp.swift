import AppKit
import SwiftUI

@main
struct TouchpadWMApp: App {
  @Environment(\.scenePhase) private var scenePhase
  @State private var state = AppState()
  @State private var keyboardMonitor = KeyboardEventMonitor()

  init() {
    NSApplication.shared.setActivationPolicy(.accessory)
  }

  var body: some Scene {
    MenuBarExtra("Touchpad WM", systemImage: "hand.draw") {
      StatusMenuView(state: state, keyboardMonitor: keyboardMonitor)
    }
    Settings {
      SettingsView(state: state)
    }
    .onChange(of: scenePhase) { _, phase in
      if phase == .active {
        state.refreshAccessibilityPermission()
      }
    }
  }
}

private struct StatusMenuView: View {
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
    SettingsLink()
    Button("Quit Touchpad WM") {
      NSApplication.shared.terminate(nil)
    }
    .onAppear {
      state.refreshAccessibilityPermission()
      keyboardMonitor.start(
        permission: { state.accessibilityPermission },
        perform: state.performLayoutCommand)
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
      Section("App Rules") {
        Text("App Rules will appear here in a later milestone.")
      }
    }
    .frame(width: 360)
    .padding()
  }
}

@MainActor
final class KeyboardEventMonitor {
  private var monitor: Any?
  private var router = KeyboardCommandRouter()

  func start(
    permission: @escaping () -> AccessibilityPermissionState,
    perform: @escaping (LayoutCommand) -> Void
  ) {
    guard monitor == nil else {
      return
    }

    monitor = NSEvent.addLocalMonitorForEvents(matching: [.flagsChanged, .keyDown]) {
      [weak self] event in
      guard let self, let input = Self.input(from: event) else {
        return event
      }
      let didDispatch = router.consume(input, permission: permission(), perform: perform)
      return didDispatch ? nil : event
    }
  }

  private static func input(from event: NSEvent) -> KeyboardInput? {
    switch event.type {
    case .flagsChanged:
      .flagsChanged(keyCode: event.keyCode)
    case .keyDown:
      .keyDown(keyCode: event.keyCode, shiftIsPressed: event.modifierFlags.contains(.shift))
    default:
      nil
    }
  }
}
