# Touchpad WM — Agent Instructions

## Scope and architecture

- This is a non-sandboxed macOS Swift package targeting macOS 15+.
- Keep all private `MultitouchSupport.framework` access inside `Sources/TouchpadWMSpike/MultitouchBridge.swift`.
- Keep gesture recognition independent of private-framework types. Add tests for every behavior change before implementation.
- Treat the console spike harness as a hardware-validation tool; reuse the bridge and recognizer in the native app rather than duplicating them.
- `Sources/TouchpadWM/AccessibilityWindowService.swift` may call the private `_AXUIElementGetWindow` ApplicationServices symbol to resolve an AXUIElement's CGWindowID (the same technique AeroSpace, yabai, and AltTab use); title- or geometry-based matching is ambiguous whenever an app has two windows with the same title. Confine that private-symbol use to this one file.
- `Sources/TouchpadWM/SwitcherGestureCoordinator.swift`, `Sources/TouchpadWM/SwitcherOverlayPanel.swift`, and `Sources/TouchpadWM/ScrollEventSuppressor.swift` are hardware/AppKit-boundary adapters (live trackpad bridge consumption, `NSPanel` windowing, and a `CGEventTap` suppressing scroll-wheel bleed-through while a switcher gesture is active, respectively) and are excluded from the coverage floor on the same basis as `AccessibilityWindowService.swift`; their decision logic is extracted into the unit-tested `SwitcherGestureRecognizer`, `SwitcherController`, and `SwitcherOverlayGeometry`.
- `TouchpadWMSpike` is a library target; the console hardware-validation harness lives in the separate `TouchpadWMSpikeConsole` executable target (`Sources/TouchpadWMSpikeConsole/main.swift`) so `TouchpadWM` can depend on and reuse `TouchpadWMSpike`'s types from production code (SwiftPM cannot link a non-test target against another executable target's symbols).

## Required quality gates

Run these before requesting review, committing, or claiming completion:

```bash
./Scripts/quality.sh
Tests/QualityGateTests/quality.sh
node --test .dev-dashboard/tests/status.test.mjs
```

`Scripts/quality.sh` runs Swift formatting lint, `swift build`, `swift test --enable-code-coverage`, and enforces at least **80% line coverage** for unit-testable production code. It excludes test/build artifacts plus the hardware- and OS-boundary adapters `MultitouchBridge.swift`, console `main.swift` (`Sources/TouchpadWMSpikeConsole/main.swift`), `AccessibilityWindowService.swift`, `SwitcherGestureCoordinator.swift`, `SwitcherOverlayPanel.swift`, and `ScrollEventSuppressor.swift`; retain their required real-hardware/real-Accessibility-permission acceptance test. Extract any pure logic out of these adapters (e.g. `AccessibilityWindowMetadata.swift`, `SwitcherGestureRecognizer.swift`, `SwitcherOverlayGeometry.swift`) into unit-tested files rather than excluding more than the adapter itself. It uses the selected Xcode toolchain's `llvm-cov` directly; do not substitute `xccov`.

To apply formatting deliberately, run:

```bash
swift package plugin --allow-writing-to-package-directory format-source-code --target TouchpadWMSpike
swift package plugin --allow-writing-to-package-directory format-source-code --target TouchpadWMSpikeTests
```

Do not bypass a failing gate. Diagnose failures before changing code. Keep `Package.resolved` current whenever package dependencies change.

## Development workflow

- Use TDD: add a focused failing test, verify the intended failure, implement the minimum behavior, then run the relevant suite and the full quality gate.
- Do not use mocks to assert mock behavior; tests must exercise observable behavior.
- Update `.dev-dashboard/status.json` before implementation work: set the matching task to `in-progress`, update `project.updatedAt`, and add a dated changelog entry. Record verification before moving to `review`; move to `done` only after final verification.
- For visual behavior changes, update a local HTML capture under `.dev-dashboard/designs/` and its `designs/manifest.json` entry.

## Local-only artifacts and Git

- `docs/`, `.dev-dashboard/`, `.agents/`, `.claude/`, `.superpowers/`, and `.build/` are local-only. Never stage or commit them.
- Stage files explicitly and inspect `git diff --cached` before committing. Never include unrelated local changes.
- Do not amend, rebase, force-push, or otherwise rewrite history unless the user explicitly requests it.
- `CLAUDE.md` is a symlink to this file; edit `AGENTS.md` only.
