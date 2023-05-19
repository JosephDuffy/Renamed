import SwiftSyntax
import SwiftSyntaxBuilder

extension SyntaxStringInterpolation {
  internal mutating func appendInterpolation<Node: SyntaxProtocol>(
    optional node: Node?
  ) {
    guard let node else { return }
    self.appendInterpolation(node)
  }
}