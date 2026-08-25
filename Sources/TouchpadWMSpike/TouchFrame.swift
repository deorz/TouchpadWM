public struct TouchContact: Equatable, Sendable {
  public let id: Int32
  public let x: Float
  public let y: Float

  public init(id: Int32, x: Float, y: Float) {
    self.id = id
    self.x = x
    self.y = y
  }
}

public struct TouchFrame: Sendable {
  public let contacts: [TouchContact]

  public init(contacts: [TouchContact]) {
    self.contacts = contacts
  }
}
