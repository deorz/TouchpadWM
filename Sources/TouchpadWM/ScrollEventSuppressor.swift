import CoreGraphics
import OSLog

/// TEMPORARY diagnostic logging while debugging why suppression isn't blocking scroll
/// bleed-through in practice. Stream it with:
///   log stream --predicate 'subsystem == "com.touchpadwm.app"' --level debug
/// Remove once the root cause is confirmed.
private let scrollSuppressorLog = Logger(
  subsystem: "com.touchpadwm.app", category: "ScrollSuppressor")

/// Suppresses continuous (trackpad) scroll-wheel events system-wide while a switcher gesture is
/// in progress. The private multitouch bridge only reads raw touch data; it has no relationship
/// to, and cannot prevent, macOS's own parallel three-finger scroll recognition, which would
/// otherwise also scroll the content of the window underneath while the switcher gesture is
/// happening. This is an AppKit/CGEventTap boundary adapter, mirroring `KeyboardEventMonitor` in
/// TouchpadWMApp.swift.
///
/// Modeled on AltTab's `ScrollwheelEvents` (github.com/lwouis/alt-tab-macos): the tap is created
/// once and left disabled until needed, toggled purely through `CGEvent.tapEnable` rather than a
/// per-event flag inside the callback, and the callback only ever blocks continuous (trackpad)
/// scroll events -- discrete mouse-wheel scrolling always passes through untouched. An earlier
/// version of this suppressor filtered every scroll-wheel event indiscriminately and tracked a
/// momentum-draining state machine to keep suppressing past gesture end; that extra state could
/// get stuck suppressing, which is why it is not reintroduced here.
final class ScrollEventSuppressor {
  private var eventTap: CFMachPort?
  private var eventTapSource: CFRunLoopSource?

  var isSuppressing = false {
    didSet {
      scrollSuppressorLog.debug(
        "isSuppressing \(oldValue) -> \(self.isSuppressing), tap present: \(self.eventTap != nil)")
      guard isSuppressing != oldValue, let eventTap else {
        return
      }
      CGEvent.tapEnable(tap: eventTap, enable: isSuppressing)
    }
  }

  func start() {
    guard eventTap == nil else {
      scrollSuppressorLog.debug("start() called again; tap already exists")
      return
    }

    let eventMask = CGEventMask(1) << CGEventType.scrollWheel.rawValue
    eventTap = CGEvent.tapCreate(
      tap: .cgSessionEventTap,
      place: .headInsertEventTap,
      options: .defaultTap,
      eventsOfInterest: eventMask,
      callback: scrollEventTapCallback,
      userInfo: Unmanaged.passUnretained(self).toOpaque())

    guard let eventTap else {
      scrollSuppressorLog.error("CGEvent.tapCreate returned nil -- not Accessibility-trusted?")
      return
    }
    eventTapSource = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, eventTap, 0)
    guard let eventTapSource else {
      scrollSuppressorLog.error("CFMachPortCreateRunLoopSource returned nil")
      self.eventTap = nil
      return
    }
    CFRunLoopAddSource(CFRunLoopGetMain(), eventTapSource, .commonModes)
    // Created disabled: the tap only starts delivering events once a switcher session actually
    // opens (see syncScrollSuppression() in SwitcherGestureCoordinator).
    CGEvent.tapEnable(tap: eventTap, enable: isSuppressing)
    scrollSuppressorLog.debug("tap created successfully, enabled: \(self.isSuppressing)")
  }

  fileprivate static func handle(
    _ type: CGEventType,
    _ event: CGEvent,
    _ userInfo: UnsafeMutableRawPointer?
  ) -> Unmanaged<CGEvent>? {
    guard let userInfo else {
      return Unmanaged.passUnretained(event)
    }
    let suppressor = Unmanaged<ScrollEventSuppressor>.fromOpaque(userInfo).takeUnretainedValue()
    if type == .tapDisabledByTimeout || type == .tapDisabledByUserInput {
      scrollSuppressorLog.debug("tap disabled by OS (timeout or user input); re-enabling if needed")
      if let eventTap = suppressor.eventTap, suppressor.isSuppressing {
        CGEvent.tapEnable(tap: eventTap, enable: true)
      }
      return Unmanaged.passUnretained(event)
    }
    let isContinuous = event.getIntegerValueField(.scrollWheelEventIsContinuous)
    guard isContinuous != 0 else {
      scrollSuppressorLog.debug("scrollWheel event NOT continuous (discrete) -- letting through")
      // Discrete (mouse-wheel) scrolling is never suppressed.
      return Unmanaged.passUnretained(event)
    }
    scrollSuppressorLog.debug("blocking continuous scrollWheel event")
    return nil
  }
}

private func scrollEventTapCallback(
  _ proxy: CGEventTapProxy,
  _ type: CGEventType,
  _ event: CGEvent,
  _ userInfo: UnsafeMutableRawPointer?
) -> Unmanaged<CGEvent>? {
  ScrollEventSuppressor.handle(type, event, userInfo)
}
