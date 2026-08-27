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
    MenuBarExtra {
      StatusMenuView(state: state)
    } label: {
      Image(nsImage: Self.menuBarIcon)
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

@MainActor
private struct SettingsView: View {
  let state: AppState
  let appRules: AppRulesController
  @State private var appSearch = ""
  @State private var iconCache = ApplicationIconCache()

  var body: some View {
    List {
      Section("Accessibility") {
        LabeledContent("Status") {
          Text(state.accessibilityPermission == .available ? "Access granted" : "Access required")
            .foregroundStyle(
              state.accessibilityPermission == .available ? .primary : .secondary)
        }
        Text("Touchpad WM needs Accessibility access to list and activate windows.")
          .font(.caption)
          .foregroundStyle(.secondary)
        Button("Open Accessibility Settings") {
          state.openAccessibilitySettings()
        }
        Button("Refresh Accessibility Status") {
          state.refreshAccessibilityPermission()
        }
      }

      Section("Apps") {
        TextField("Search applications", text: $appSearch)
        ForEach(appRules.applications(matching: appSearch)) { application in
          HStack(spacing: 12) {
            Image(nsImage: iconCache.icon(for: application))
              .resizable()
              .frame(width: 32, height: 32)
            VStack(alignment: .leading, spacing: 2) {
              Text(application.name)
              Text(application.bundleIdentifier)
                .font(.caption)
                .lineLimit(1)
                .foregroundStyle(.secondary)
            }
            Spacer(minLength: 12)
            Toggle("Include in Picker", isOn: pickerBinding(for: application))
              .labelsHidden()
              .toggleStyle(.switch)
              .accessibilityLabel("Include \(application.name) in Picker")
          }
          .padding(.vertical, 2)
        }
      }
    }
    .frame(width: 460, height: 600)
    .contentMargins(8, for: .scrollContent)
    .onAppear {
      appRules.refresh()
    }
  }

  private func pickerBinding(for application: InstalledApplication) -> Binding<Bool> {
    Binding(
      get: { appRules.rule(for: application.bundleIdentifier).includeInSwitcher },
      set: { includeInSwitcher in
        appRules.setRule(
          AppRule(includeInSwitcher: includeInSwitcher),
          for: application.bundleIdentifier)
      })
  }
}
