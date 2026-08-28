import SwiftUI

@MainActor
struct SettingsView: View {
  let state: AppState
  let appRules: AppRulesController

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
    case .apps:
      AppsSettingsView(appRules: appRules)
    case nil:
      ContentUnavailableView("Select a setting", systemImage: "gearshape")
    }
  }
}

private enum SettingsSection: String, CaseIterable, Hashable, Identifiable {
  case accessibility = "Accessibility"
  case apps = "Apps"

  var id: Self { self }

  var systemImage: String {
    switch self {
    case .accessibility:
      "accessibility"
    case .apps:
      "square.grid.2x2"
    }
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
