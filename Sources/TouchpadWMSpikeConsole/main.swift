import Dispatch
import Foundation
import TouchpadWMSpike

let bridge = MultitouchBridge()
guard bridge.start() else {
  fputs("ERROR: Multitouch listener did not start.\n", stderr)
  exit(1)
}

print("Listening for multi-finger gestures (default: 3 fingers). Press Control-C to stop.")
Task {
  var recognizer = MultiFingerGestureRecognizer()
  for await frame in bridge.frames() {
    for event in recognizer.consume(frame) {
      print("GESTURE \(event)")
    }
  }
}
dispatchMain()
