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
        } else if let variableDecl = declaration.as(VariableDeclSyntax.self) {
            return try expansion(of: node, providingPeersOf: variableDecl, in: context, previousName: previousName.content.text)
        } else {
            throw ErrorDiagnosticMessage(id: "invalid-declaration-type", message: "'Renamed' can only be applied to structs, classes, and variables")
        }
    }

    private static func expansion<Context: MacroExpansionContext>(
        of node: AttributeSyntax,
        providingPeersOf declaration: some DeclGroupSyntax,
        in context: Context,
        previousName: String
    ) throws -> [DeclSyntax] {
        guard let identifiedDeclaration = declaration.asProtocol(IdentifiedDeclSyntax.self) else {
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

    private static func expansion<Context: MacroExpansionContext>(
        of node: AttributeSyntax,
        providingPeersOf declaration: VariableDeclSyntax,
        in context: Context,
        previousName: String
    ) throws -> [DeclSyntax] {
        guard
            let binding = declaration.bindings.first,
            let propertyName = binding.pattern.as(IdentifierPatternSyntax.self)?.identifier.text,
            let type = binding.typeAnnotation?.type.as(SimpleTypeIdentifierSyntax.self)?.name
        else {
            throw ErrorDiagnosticMessage(id: "missing-variable-type", message: "'Renamed' requires a variable to be explicitly typed")
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
            @available(*, deprecated, renamed: "\(raw: propertyName)")
            \(raw: scope)var \(raw: previousName): \(raw: type) {
                \(raw: propertyName)
            }
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
