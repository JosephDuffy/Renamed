import Foundation
import SwiftDiagnostics
import SwiftSyntax
import SwiftSyntaxMacros

public struct Renamed: PeerMacro {
    public static func expansion<Context: MacroExpansionContext, Declaration: DeclSyntaxProtocol>(
        of node: AttributeSyntax,
        providingPeersOf declaration: Declaration,
        in context: Context
    ) throws -> [DeclSyntax] {
        guard
            case .argumentList(let arguments) = node.argument,
            let firstElement = arguments.first,
            let stringLiteral = firstElement.expression.as(StringLiteralExprSyntax.self),
            stringLiteral.segments.count == 1,
            case .stringSegment(let previousName)? = stringLiteral.segments.first
        else {
            throw ErrorDiagnosticMessage(id: "missing-name-parameter", message: "'Renamed' requires a string literal containing the name of the old symbol")
        }

        if let structDecl = declaration.as(StructDeclSyntax.self) {
            return try expansion(of: node, providingPeersOf: structDecl, in: context, previousName: previousName.content.text)
        } else if let classDecl = declaration.as(ClassDeclSyntax.self) {
            return try expansion(of: node, providingPeersOf: classDecl, in: context, previousName: previousName.content.text)
        } else {
            throw InvalidDeclarationTypeError()
        }
    }

    private static func expansion<Context: MacroExpansionContext>(
        of node: AttributeSyntax,
        providingPeersOf declaration: some DeclGroupSyntax,
        in context: Context,
        previousName: String
    ) throws -> [DeclSyntax] {
        guard let identifiedDeclaration = declaration as? IdentifiedDeclSyntax else {
            throw InvalidDeclarationTypeError()
        }

        let scope = ({
            for modifier in declaration.modifiers ?? [] {
                switch (modifier.name.tokenKind) {
                case .keyword(.public):
                    return "public "
                case .keyword(.internal):
                    return "internal "
                case .keyword(.fileprivate):
                    return "fileprivate "
                case .keyword(.private):
                    return "private "
                default:
                    break
                }
            }

            return ""
        })()

        return [
            """
            @available(*, deprecated, renamed: "\(raw: identifiedDeclaration.identifier.text)")
            \(raw: scope)typealias \(raw: previousName) = \(raw: identifiedDeclaration.identifier.text)
            """
        ]
    }
}

private struct InvalidDeclarationTypeError: Error {}

private struct ErrorDiagnosticMessage: DiagnosticMessage, Error {
    let message: String
    let diagnosticID: MessageID
    let severity: DiagnosticSeverity

    init(id: String, message: String) {
        self.message = message
        diagnosticID = MessageID(domain: "uk.josephduffy.Renamed", id: id)
        severity = .error
    }
}
