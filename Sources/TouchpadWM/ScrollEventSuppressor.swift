import CoreGraphics

/// Suppresses continuous (trackpad) scroll-wheel events system-wide while a switcher gesture is
/// in progress. The private multitouch bridge only reads raw touch data; it has no relationship
/// to, and cannot prevent, macOS's own parallel three-finger scroll recognition, which would
/// otherwise also scroll the content of the window underneath while the switcher gesture is
/// happening. This is an AppKit/CGEventTap boundary adapter.
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
      guard isSuppressing != oldValue, let eventTap else {
        return
      }
      CGEvent.tapEnable(tap: eventTap, enable: isSuppressing)
    }
  }

  func start() {
    guard eventTap == nil else {
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
      return
    }
    eventTapSource = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, eventTap, 0)
    guard let eventTapSource else {
      self.eventTap = nil
      return
    }
    CFRunLoopAddSource(CFRunLoopGetMain(), eventTapSource, .commonModes)
    // Created disabled: the tap only starts delivering events once a switcher session actually
    // opens (see syncScrollSuppression() in SwitcherGestureCoordinator).
    CGEvent.tapEnable(tap: eventTap, enable: isSuppressing)
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
      if let eventTap = suppressor.eventTap, suppressor.isSuppressing {
        CGEvent.tapEnable(tap: eventTap, enable: true)
      }
      return Unmanaged.passUnretained(event)
    }
    guard event.getIntegerValueField(.scrollWheelEventIsContinuous) != 0 else {
      // Discrete (mouse-wheel) scrolling is never suppressed.
      return Unmanaged.passUnretained(event)
    }
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
