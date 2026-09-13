# Touchpad WM

A native macOS menu bar app for switching windows with trackpad gestures. Open the window picker, slide your fingers to select a window, and lift them to activate it.

## Features

- Open the picker with a three-, four-, or five-finger touch or vertical swipe.
- Move vertically through windows without leaving the trackpad.
- Customize activation and selection sensitivity, haptic feedback, picker width, and visible rows.
- Exclude applications using exact bundle IDs or regular expressions.
- Start at login and optionally hide the menu bar icon.

## Requirements

- macOS 15 or later.
- A compatible multitouch trackpad.
- Xcode with Swift 6.2 or later to build from source.
- Accessibility permission to list and activate windows.

Touchpad WM is not sandboxed and uses private macOS APIs for multitouch input and window identification. Compatibility may change with macOS updates.

## Build and run

From the repository root:

```bash
./Scripts/run-app.sh
```

This builds a debug app bundle, signs it ad hoc, and opens it. Use the app bundle rather than the bare SwiftPM executable for normal use.

To build a release app without launching it:

```bash
./Scripts/build-app.sh release
```

The script prints the path to `TouchpadWM.app`. You can copy it to `/Applications` and open it from Finder.

To create a release ZIP:

```bash
./Scripts/release-app.sh
```

Release artifacts are ad-hoc signed, not Developer ID signed or notarized.

## First launch

1. Open Touchpad WM settings from its menu bar icon.
2. In **Accessibility**, click **Open Accessibility Settings** and enable Touchpad WM in **System Settings → Privacy & Security → Accessibility**.
3. Return to the app and click **Refresh Accessibility Status** if needed.
4. Touch the trackpad with **three fingers** (the default gesture) to open the picker.
5. Move your fingers up or down to select a window, then lift them to activate it.

Under **Gestures**, choose a different finger count or use **Swipe up** / **Swipe down** to open the picker instead of a touch. If a gesture also triggers a macOS action, adjust the conflicting system gesture in System Settings.

Under **Apps**, use the **+** button beside an application to exclude it, or add a custom bundle ID regular expression. Patterns are case-insensitive; for example, `^com\.example\.` excludes bundle IDs beginning with `com.example.`.

Under **General**, configure startup at login and menu bar visibility. If you hide the icon, reopen Touchpad WM from Spotlight or Finder to access settings.

## Development

```bash
swift build
swift test
```

Run both required quality gates before submitting changes:

```bash
./Scripts/quality.sh
Tests/QualityGateTests/quality.sh
```

The main gate runs Swift formatting lint, builds the package, runs tests with coverage, and enforces at least **80% line coverage** for unit-testable production code. It requires Python 3 and the selected Xcode toolchain's `llvm-cov`. UI and hardware/OS-boundary adapters are excluded from the coverage floor; real-trackpad and Accessibility-permission checks remain necessary.

### Project layout

- `Sources/TouchpadWM/` — native app, settings, window catalogue, picker, and Accessibility integration.
- `Sources/TouchpadWMSpike/` — shared multitouch bridge and framework-independent gesture recognition.
- `Sources/TouchpadWMSpikeConsole/` — console harness for validating trackpad input on real hardware.
- `Tests/` — unit tests and quality-gate tests.
- `Scripts/` — app bundling, release packaging, and quality checks.
- `Resources/` — app and menu bar icons.

To run the hardware-validation harness:

```bash
swift run TouchpadWMSpike
```

It logs multi-finger gesture events until you press **Control-C**; it does not launch the window picker.

Keep private `MultitouchSupport.framework` access in `MultitouchBridge.swift` and private window-ID lookup in `AccessibilityWindowService.swift`. Add focused tests before changing gesture behavior. See [AGENTS.md](AGENTS.md) for project conventions.

## Dependencies

- [OpenMultitouchSupport](https://github.com/Kyome22/OpenMultitouchSupport) — multitouch input bridge.
- [swift-format](https://github.com/swiftlang/swift-format) — Swift formatting and linting.
