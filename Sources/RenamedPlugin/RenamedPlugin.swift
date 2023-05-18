import SwiftCompilerPlugin
import SwiftSyntaxMacros

@main
struct RenamedPlugin: CompilerPlugin {
  let providingMacros: [Macro.Type] = [
    Renamed.self,
  ]
}
