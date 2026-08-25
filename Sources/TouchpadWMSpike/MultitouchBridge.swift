import OpenMultitouchSupport

struct RawTouchSample: Equatable {
  let id: Int32
  let x: Float
  let y: Float
}

public final class MultitouchBridge {
  private let manager = OMSManager.shared

  public init() {}

  public func start() -> Bool {
    manager.startListening()
  }

  public func frames() -> AsyncStream<TouchFrame> {
    AsyncStream { continuation in
      let task = Task { [manager] in
        defer { continuation.finish() }

        for await touches in manager.touchDataStream {
          let samples = touches.map {
            RawTouchSample(
              id: $0.id,
              x: $0.position.x,
              y: $0.position.y
            )
          }
          continuation.yield(Self.frame(from: samples))
        }
      }
      continuation.onTermination = { _ in
        task.cancel()
      }
    }
  }

  public func stop() {
    manager.stopListening()
  }

  static func frame(from samples: [RawTouchSample]) -> TouchFrame {
    TouchFrame(
      contacts: samples.map {
        TouchContact(id: $0.id, x: $0.x, y: $0.y)
      }
    )
  }
}
