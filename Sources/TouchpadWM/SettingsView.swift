import Foundation
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
  @State private var newExclusionPattern = ""
  @State private var patternError: String?
  @State private var iconCache = ApplicationIconCache()

  var body: some View {
    List {
      Section("Custom Exclusions") {
        HStack(spacing: 8) {
          TextField("Bundle ID regex", text: $newExclusionPattern)
            .textFieldStyle(.roundedBorder)
            .onSubmit(addExclusionPattern)

          Button {
            addExclusionPattern()
          } label: {
            Image(systemName: "plus")
          }
          .buttonStyle(.borderless)
          .disabled(
            newExclusionPattern
              .trimmingCharacters(in: .whitespacesAndNewlines)
              .isEmpty
          )
          .accessibilityLabel("Add custom exclusion")
          .help("Add custom exclusion")
        }

        if let patternError {
          Text(patternError)
            .font(.caption)
            .foregroundStyle(.red)
        }

        ForEach(appRules.exclusionPatterns) { exclusion in
          ExclusionPatternRow(appRules: appRules, pattern: exclusion)
        }

        Text(
          "Use + to add an editable exact regex. "
            + "Patterns match bundle identifiers case-insensitively. "
            + "Example: ^com\\.checkpoint\\."
        )
        .font(.caption)
        .foregroundStyle(.secondary)
      }

      Section("Applications") {
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

            Button {
              appRules.addApplicationExclusion(for: application.bundleIdentifier)
            } label: {
              Image(systemName: "plus")
            }
            .buttonStyle(.borderless)
            .disabled(appRules.hasApplicationExclusion(for: application.bundleIdentifier))
            .accessibilityLabel("Add \(application.name) to Picker exclusions")
            .help("Add an exact bundle ID regex to exclusions")
          }
          .padding(.vertical, 2)
        }
      }
    }
    .listStyle(.inset)
    .contentMargins(8, for: .scrollContent)
    .navigationTitle("Apps")
    .searchable(
      text: $appSearch,
      placement: .toolbar,
      prompt: "Search applications"
    )
    .onAppear {
      appRules.refresh()
    }
  }

  private func addExclusionPattern() {
    guard appRules.addExclusionPattern(newExclusionPattern) else {
      patternError = "Enter a valid, non-duplicate regular expression."
      return
    }

    newExclusionPattern = ""
    patternError = nil
  }
}

@MainActor
private struct ExclusionPatternRow: View {
  let appRules: AppRulesController
  let pattern: AppExclusionPattern

  @State private var draft: String
  @State private var errorMessage: String?

  init(appRules: AppRulesController, pattern: AppExclusionPattern) {
    self.appRules = appRules
    self.pattern = pattern
    _draft = State(initialValue: pattern.pattern)
  }

  var body: some View {
    VStack(alignment: .leading, spacing: 4) {
      HStack(spacing: 8) {
        TextField("Bundle ID regex", text: $draft)
          .font(.system(.body, design: .monospaced))
          .textFieldStyle(.roundedBorder)
          .onSubmit(save)

        Button {
          save()
        } label: {
          Image(systemName: "checkmark")
        }
        .buttonStyle(.borderless)
        .disabled(draft == currentPattern)
        .accessibilityLabel("Save exclusion")
        .help("Save exclusion")

        Button {
          appRules.removeExclusionPattern(pattern)
        } label: {
          Image(systemName: "trash")
        }
        .buttonStyle(.borderless)
        .foregroundStyle(.secondary)
        .accessibilityLabel("Remove exclusion")
        .help("Remove exclusion")
      }

      if let errorMessage {
        Text(errorMessage)
          .font(.caption)
          .foregroundStyle(.red)
      }
    }
  }

  private var currentPattern: String {
    appRules.exclusionPatterns.first(where: { $0.id == pattern.id })?.pattern
      ?? pattern.pattern
  }

  private func save() {
    guard appRules.updateExclusionPattern(pattern, to: draft) else {
      errorMessage = "Enter a valid, non-duplicate regular expression."
      return
    }

    errorMessage = nil
  }
}
