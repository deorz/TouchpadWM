struct TouchContact: Equatable, Sendable {
  let id: Int32
  let x: Float
  let y: Float
}

struct TouchFrame: Sendable {
  let contacts: [TouchContact]
}
