import SwiftUI

@MainActor
struct SettingsView: View {
  let state: AppState
  let appRules: AppRulesController
  let gesturePreferences: GesturePreferences

  @State private var selection: SettingsSection? = .accessibility

  var body: some View {
    NavigationSplitView {
      List(SettingsSection.allCases, selection: $selection) { section in
        Label(section.rawValue, systemImage: section.systemImage)
          .tag(section)
      }
      .listStyle(.sidebar)
      .navigationTitle("Settings")
      .navigationSplitViewColumnWidth(min: 180, ideal: 200, max: 280)
    } detail: {
      NavigationStack {
        detailView
      }
    }
    .navigationSplitViewStyle(.balanced)
    .frame(minWidth: 760, minHeight: 520)
    .onAppear {
      appRules.refresh()
    }
  }

  @ViewBuilder
  private var detailView: some View {
    switch selection {
    case .accessibility:
      AccessibilitySettingsView(state: state)
    case .gestures:
      GesturesSettingsView(preferences: gesturePreferences)
    case .apps:
      AppsSettingsView(appRules: appRules)
    case nil:
      ContentUnavailableView("Select a setting", systemImage: "gearshape")
    }
  }
}

private enum SettingsSection: String, CaseIterable, Hashable, Identifiable {
  case accessibility = "Accessibility"
  case gestures = "Gestures"
  case apps = "Apps"

  var id: Self { self }

  var systemImage: String {
    switch self {
    case .accessibility:
      "accessibility"
    case .gestures:
      "hand.draw"
    case .apps:
      "square.grid.2x2"
    }
  }
}

@MainActor
private struct GesturesSettingsView: View {
  let preferences: GesturePreferences

  var body: some View {
    Form {
      Section("Picker") {
        Picker("Open picker with", selection: pickerTriggerBinding) {
          ForEach(PickerTrigger.allCases, id: \.self) { trigger in
            Text(trigger.label).tag(trigger)
          }
        }

        VStack(alignment: .leading, spacing: 8) {
          Slider(
            value: sensitivityBinding,
            in: 0...Double(GestureSensitivity.allCases.count - 1),
            step: 1,
            label: { Text("Sensitivity") },
            minimumValueLabel: { Text("Less") },
            maximumValueLabel: { Text("More") }
          )
          .accessibilityValue(Text(preferences.sensitivity.accessibilityLabel))

          Text("Adjust how much finger movement changes the selected window.")
            .font(.caption)
            .foregroundStyle(.secondary)
        }

        Picker("Haptic feedback", selection: hapticStrengthBinding) {
          ForEach(HapticFeedbackStrength.allCases, id: \.self) { strength in
            Text(strength.label).tag(strength)
          }
        }
        .pickerStyle(.segmented)

        Text(
          "macOS uses system haptic patterns; levels choose a softer or more pronounced response."
        )
        .font(.caption)
        .foregroundStyle(.secondary)
      }
    }
    .formStyle(.grouped)
    .navigationTitle("Gestures")
    .scenePadding()
  }

  private var pickerTriggerBinding: Binding<PickerTrigger> {
    Binding(
      get: { preferences.pickerTrigger },
      set: { preferences.pickerTrigger = $0 })
  }

  private var sensitivityBinding: Binding<Double> {
    Binding(
      get: { Double(preferences.sensitivity.rawValue) },
      set: { value in
        let index = Int(value.rounded())
        preferences.sensitivity = GestureSensitivity(rawValue: index) ?? .medium
      })
  }

  private var hapticStrengthBinding: Binding<HapticFeedbackStrength> {
    Binding(
      get: { preferences.hapticStrength },
      set: { preferences.hapticStrength = $0 })
  }
}

@MainActor
private struct AccessibilitySettingsView: View {
  let state: AppState

  var body: some View {
    Form {
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
    }
    .formStyle(.grouped)
    .navigationTitle("Accessibility")
    .scenePadding()
  }
}

@MainActor
private struct AppsSettingsView: View {
  let appRules: AppRulesController

  @State private var appSearch = ""
  @State private var iconCache = ApplicationIconCache()

  var body: some View {
    List {
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
    .listStyle(.inset)
    .contentMargins(8, for: .scrollContent)
    .navigationTitle("Apps")
    .searchable(
      text: $appSearch,
      placement: .toolbar,
      prompt: "Search applications")
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
