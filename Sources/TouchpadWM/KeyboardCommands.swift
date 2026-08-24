enum LayoutCommand: Equatable {
  case leftHalf
  case rightHalf
  case leftThreeQuarters
  case rightQuarter
  case topRightQuarter
  case bottomRightQuarter
  case masterStack
}

enum KeyboardInput: Equatable {
  case flagsChanged(keyCode: UInt16)
  case keyDown(keyCode: UInt16, shiftIsPressed: Bool)
}

struct KeyboardCommandInterpreter {
  private var rightOptionIsPressed = false

  mutating func consume(_ input: KeyboardInput) -> LayoutCommand? {
    switch input {
    case .flagsChanged(let keyCode):
      if keyCode == 61 {
        rightOptionIsPressed.toggle()
      }
      return nil
    case .keyDown(let keyCode, let shiftIsPressed):
      guard rightOptionIsPressed else {
        return nil
      }
      return command(for: keyCode, shiftIsPressed: shiftIsPressed)
    }
  }

  private func command(for keyCode: UInt16, shiftIsPressed: Bool) -> LayoutCommand? {
    switch (keyCode, shiftIsPressed) {
    case (123, false): .leftHalf
    case (124, false): .rightHalf
    case (126, false): .topRightQuarter
    case (125, false): .bottomRightQuarter
    case (123, true): .leftThreeQuarters
    case (124, true): .rightQuarter
    case (126, true): .masterStack
    default: nil
    }
  }
}

struct KeyboardCommandRouter {
  private var interpreter = KeyboardCommandInterpreter()

  mutating func consume(
    _ input: KeyboardInput,
    permission: AccessibilityPermissionState,
    perform: (LayoutCommand) -> Void
  ) -> Bool {
    guard let command = interpreter.consume(input), permission == .available else {
      return false
    }
    perform(command)
    return true
  }
}
