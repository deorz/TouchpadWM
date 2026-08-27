import AppKit
import SwiftUI

private enum SettingsSection: String, CaseIterable, Identifiable {
  case general
  case applications

  var id: Self { self }

  var title: String {
    switch self {
    case .general:
      return "General"
    case .applications:
      return "Applications"
    }
  }

  var systemImage: String {
    switch self {
    case .general:
      return "gearshape"
    case .applications:
      return "macwindow.on.rectangle"
    }
  }
}

@MainActor
struct SettingsView: View {
  let state: AppState
  let appRules: AppRulesController

  @State private var selection: SettingsSection = .general
  @State private var appSearch = ""
  @State private var iconCache = ApplicationIconCache()

  var body: some View {
    NavigationSplitView {
      SettingsSidebar(selection: $selection)
    } detail: {
      SettingsDetailView(
        selection: selection,
        state: state,
        appRules: appRules,
        appSearch: $appSearch,
        iconCache: iconCache
      )
    }
    .frame(minWidth: 760, idealWidth: 860, minHeight: 520, idealHeight: 620)
    .onAppear {
      appRules.refresh()
    }
  }
}

@MainActor
private struct SettingsSidebar: View {
  @Binding var selection: SettingsSection

  var body: some View {
    List(selection: $selection) {
      Section("Settings") {
        ForEach(SettingsSection.allCases) { section in
          Label(section.title, systemImage: section.systemImage)
            .tag(section)
        }
      }
    }
    .listStyle(.sidebar)
    .navigationTitle("Touchpad WM")
    .navigationSplitViewColumnWidth(min: 180, ideal: 210, max: 250)
  }
}

@MainActor
private struct SettingsDetailView: View {
  let selection: SettingsSection
  let state: AppState
  let appRules: AppRulesController
  @Binding var appSearch: String
  let iconCache: ApplicationIconCache

  var body: some View {
    ScrollView {
      VStack(alignment: .leading, spacing: 22) {
        switch selection {
        case .general:
          AccessibilitySettingsView(state: state)
        case .applications:
          ApplicationsSettingsView(
            appRules: appRules,
            appSearch: $appSearch,
            iconCache: iconCache
          )
        }
      }
      .frame(maxWidth: 700, alignment: .leading)
      .padding(.horizontal, 32)
      .padding(.vertical, 28)
      .frame(maxWidth: .infinity, alignment: .top)
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
  }
}

@MainActor
private struct AccessibilitySettingsView: View {
  let state: AppState

  var body: some View {
    let isAvailable = state.accessibilityPermission == .available

    VStack(alignment: .leading, spacing: 20) {
      SettingsPageHeader(
        symbolName: "hand.raised",
        title: "General",
        subtitle: "Control how Touchpad WM accesses and manages your windows."
      )

      SettingsCard {
        VStack(alignment: .leading, spacing: 18) {
          HStack(alignment: .top, spacing: 14) {
            Image(
              systemName: isAvailable
                ? "checkmark.circle.fill"
                : "exclamationmark.triangle.fill"
            )
            .font(.system(size: 24, weight: .semibold))
            .foregroundStyle(isAvailable ? Color.green : Color.orange)

            VStack(alignment: .leading, spacing: 4) {
              Text(isAvailable ? "Accessibility access enabled" : "Accessibility access required")
                .font(.headline.weight(.semibold))
              Text(
                isAvailable
                  ? "Touchpad WM can list and activate application windows."
                  : "Grant access in System Settings to enable window switching."
              )
              .font(.subheadline)
              .foregroundStyle(.secondary)
            }

            Spacer(minLength: 12)

            Text(isAvailable ? "Ready" : "Required")
              .font(.subheadline.weight(.medium))
              .foregroundStyle(isAvailable ? Color.green : Color.orange)
          }

          Divider()

          HStack(spacing: 10) {
            glassProminentButton(action: { state.openAccessibilitySettings() }) {
              Label("Open System Settings", systemImage: "gearshape")
            }

            Button("Refresh Status") {
              state.refreshAccessibilityPermission()
            }
            .buttonStyle(.bordered)
          }
          .controlSize(.large)
        }
      }

      Text(
        "Touchpad WM uses Accessibility access to discover windows, keep their order, and activate the selected window."
      )
      .font(.caption)
      .foregroundStyle(.secondary)
      .padding(.horizontal, 4)
    }
  }
}

@MainActor
private struct ApplicationsSettingsView: View {
  let appRules: AppRulesController
  @Binding var appSearch: String
  let iconCache: ApplicationIconCache

  private var filteredApplications: [InstalledApplication] {
    appRules.applications(matching: appSearch)
  }

  private var resultSummary: String {
    let total = appRules.applications.count
    let filtered = filteredApplications.count
    let applicationWord = total == 1 ? "application" : "applications"

    if appSearch.isEmpty {
      return "\(total) \(applicationWord)"
    }
    return "\(filtered) of \(total) \(applicationWord)"
  }

  var body: some View {
    VStack(alignment: .leading, spacing: 20) {
      SettingsPageHeader(
        symbolName: "macwindow.on.rectangle",
        title: "Applications",
        subtitle: "Choose which applications appear in the three-finger window switcher."
      )

      HStack {
        Text(resultSummary)
          .font(.subheadline)
          .foregroundStyle(.secondary)
        Spacer()
      }

      SettingsCard {
        VStack(spacing: 0) {
          if filteredApplications.isEmpty {
            VStack(spacing: 10) {
              Image(systemName: "magnifyingglass")
                .font(.system(size: 24))
                .foregroundStyle(.secondary)
              Text(appSearch.isEmpty ? "No applications found" : "No matching applications")
                .font(.headline)
              Text(
                appSearch.isEmpty
                  ? "Installed applications will appear here."
                  : "Try a different name or bundle identifier."
              )
              .font(.subheadline)
              .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 30)
          } else {
            ForEach(filteredApplications) { application in
              ApplicationRuleRow(
                application: application,
                icon: iconCache.icon(for: application),
                includeInPicker: pickerBinding(for: application)
              )

              if application.id != filteredApplications.last?.id {
                Divider()
                  .padding(.leading, 52)
              }
            }
          }
        }
      }
    }
    .toolbar {
      ToolbarItem(placement: .primaryAction) {
        Button {
          appRules.refresh()
        } label: {
          Label("Refresh Applications", systemImage: "arrow.clockwise")
        }
        .help("Refresh installed applications")
      }
    }
    .searchable(text: $appSearch, placement: .toolbar, prompt: "Search applications")
  }

  private func pickerBinding(for application: InstalledApplication) -> Binding<Bool> {
    Binding(
      get: { appRules.rule(for: application.bundleIdentifier).includeInSwitcher },
      set: { includeInSwitcher in
        appRules.setRule(
          AppRule(includeInSwitcher: includeInSwitcher),
          for: application.bundleIdentifier
        )
      }
    )
  }
}

@MainActor
private struct ApplicationRuleRow: View {
  let application: InstalledApplication
  let icon: NSImage
  @Binding var includeInPicker: Bool

  var body: some View {
    HStack(spacing: 12) {
      Image(nsImage: icon)
        .resizable()
        .aspectRatio(contentMode: .fit)
        .frame(width: 40, height: 40)
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))

      VStack(alignment: .leading, spacing: 3) {
        Text(application.name)
          .lineLimit(1)
        Text(application.bundleIdentifier)
          .font(.caption)
          .foregroundStyle(.secondary)
          .lineLimit(1)
      }

      Spacer(minLength: 12)

      Toggle("Include in Picker", isOn: $includeInPicker)
        .labelsHidden()
        .toggleStyle(.switch)
        .accessibilityLabel("Include \(application.name) in Picker")
    }
    .frame(maxWidth: .infinity, minHeight: 56, alignment: .leading)
  }
}

@MainActor
private struct SettingsPageHeader: View {
  let symbolName: String
  let title: String
  let subtitle: String

  var body: some View {
    HStack(alignment: .top, spacing: 14) {
      Image(systemName: symbolName)
        .font(.system(size: 24, weight: .medium))
        .foregroundStyle(.tint)
        .frame(width: 56, height: 56)
        .background(
          Color.accentColor.opacity(0.12),
          in: RoundedRectangle(cornerRadius: 16, style: .continuous)
        )

      VStack(alignment: .leading, spacing: 5) {
        Text(title)
          .font(.system(size: 28, weight: .semibold))
        Text(subtitle)
          .font(.body)
          .foregroundStyle(.secondary)
          .fixedSize(horizontal: false, vertical: true)
      }
    }
  }
}

@MainActor
private struct SettingsCard<Content: View>: View {
  private let content: Content

  init(@ViewBuilder content: () -> Content) {
    self.content = content()
  }

  var body: some View {
    if #available(macOS 26.0, *) {
      content
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(20)
        .glassEffect(
          .regular,
          in: RoundedRectangle(cornerRadius: 20, style: .continuous)
        )
    } else {
      content
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(20)
        .background(
          .regularMaterial,
          in: RoundedRectangle(cornerRadius: 20, style: .continuous)
        )
    }
  }
}

@MainActor
@ViewBuilder
private func glassProminentButton<Label: View>(
  action: @escaping () -> Void,
  @ViewBuilder label: () -> Label
) -> some View {
  if #available(macOS 26.0, *) {
    Button(action: action) {
      label()
    }
    .buttonStyle(.glassProminent)
  } else {
    Button(action: action) {
      label()
    }
    .buttonStyle(.borderedProminent)
  }
}
