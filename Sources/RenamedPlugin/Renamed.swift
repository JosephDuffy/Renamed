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
        } else if let enumDecl = declaration.as(EnumDeclSyntax.self) {
            return try expansion(of: node, providingPeersOf: enumDecl, in: context, previousName: previousName.content.text)
        } else if let typealiasDecl = declaration.as(TypealiasDeclSyntax.self) {
            return try expansion(of: node, providingPeersOf: typealiasDecl, in: context, previousName: previousName.content.text)
        } else if let functionDecl = declaration.as(FunctionDeclSyntax.self) {
            return try expansion(of: node, providingPeersOf: functionDecl, in: context, previousName: previousName.content.text)
        } else if let variableDecl = declaration.as(VariableDeclSyntax.self) {
            return try expansion(of: node, providingPeersOf: variableDecl, in: context, previousName: previousName.content.text)
        } else {
            throw ErrorDiagnosticMessage(id: "invalid-declaration-type", message: "'Renamed' can only be applied to structs, classes, enums, typealiases, and variables")
        }
    }

    private static func expansion<Context: MacroExpansionContext>(
        of node: AttributeSyntax,
        providingPeersOf declaration: some IdentifiedDeclSyntax & ModifiedDeclSyntax,
        in context: Context,
        previousName: String
    ) throws -> [DeclSyntax] {
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
            @available(*, deprecated, renamed: "\(raw: declaration.identifier.text)")
            \(raw: scope)typealias \(raw: previousName) = \(raw: declaration.identifier.text)
            """
        ]
    }

    private static func expansion<Context: MacroExpansionContext>(
        of node: AttributeSyntax,
        providingPeersOf declaration: FunctionDeclSyntax,
        in context: Context,
        previousName: String
    ) throws -> [DeclSyntax] {
        let scope: DeclModifierSyntax? = ({
            for modifier in declaration.modifiers ?? [] {
                switch (modifier.name.tokenKind) {
                case .keyword(.public):
                    return modifier
                case .keyword(.internal):
                    return modifier
                case .keyword(.fileprivate):
                    return modifier
                case .keyword(.private):
                    return modifier
                default:
                    break
                }
            }

            return nil
        })()

        let functionNameSplit = previousName.split(separator: "(", maxSplits: 1)

        let newParameters: String

        let argumentsAndTypes = declaration.signature.input.parameterList.map { parameter -> (TokenSyntax?, TypeSyntaxProtocol) in
            let type = parameter.type

            if parameter.firstName.text == "_" {
                return (nil, type)
            } else {
                return (parameter.firstName, type)
            }
        }

        let parametersInBody = argumentsAndTypes.map(\.0).enumerated().map { index, argumentName in
            if let argumentName {
                return "\(argumentName): arg\(index)"
            } else {
                return "arg\(index)"
            }
        }.joined(separator: ", ")
        let body: DeclSyntax = "\(declaration.identifier)(\(raw: parametersInBody))"

        if functionNameSplit.count == 2 {
            guard functionNameSplit[1].last == ")" else {
                throw ErrorDiagnosticMessage(id: "invalid-function-signature", message: "The provided function signature is not valid. Missing matching closing parenthesis.")
            }

            let parametersSplit = functionNameSplit[1].dropLast().split(separator: ":")

            guard declaration.signature.input.parameterList.count == parametersSplit.count else {
                throw ErrorDiagnosticMessage(id: "invalid-function-parameter-count", message: "The old function signature must have the same number of parameters as the function 'Renamed' is applied to.")
            }

            newParameters = zip(parametersSplit, argumentsAndTypes.map(\.1)).enumerated().map { index, argumentLabelAndType in
                "\(argumentLabelAndType.0) arg\(index): \(argumentLabelAndType.1)"
            }.joined(separator: ", ")
        } else {
            guard declaration.signature.input.parameterList.count == 0 else {
                throw ErrorDiagnosticMessage(id: "invalid-function-parameter-count", message: "The old function signature must have the same number of parameters as the function 'Renamed' is applied to.")
            }

            newParameters = ""
        }

        var renamedParameters = declaration.signature.input.parameterList.map { $0.firstName.text }.joined(separator: ":")
        if !renamedParameters.isEmpty {
            renamedParameters = "(" + renamedParameters + ":)"
        }

        let functionName = functionNameSplit[0]
        let signature: DeclSyntax = "\(raw: functionName)(\(raw: newParameters)) \(optional: declaration.signature.output)"

        return [
            """
            @available(*, deprecated, renamed: "\(declaration.identifier)\(raw: renamedParameters)")
            \(optional: scope)func \(signature){
                \(body)
            }
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
            // Variables declared with some values, e.g. `var test = 1`, will have an implicit type. These could be supported by looking a
            // initialiser but it gets complex once basic types are done, e.g. to infer the type of an array.
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

        lazy var immutableProperty: DeclSyntax = """
        @available(*, deprecated, renamed: "\(raw: propertyName)")
        \(raw: scope)var \(raw: previousName): \(raw: type) {
            \(raw: propertyName)
        }
        """

        lazy var mutableProperty: DeclSyntax = """
        @available(*, deprecated, renamed: "\(raw: propertyName)")
        \(raw: scope)var \(raw: previousName): \(raw: type) {
            get {
                \(raw: propertyName)
            }
            set {
                \(raw: propertyName) = newValue
            }
        }
        """

        switch declaration.bindingKeyword.tokenKind {
        case .keyword(.let):
            return [
                immutableProperty
            ]
        case .keyword(.var):
            guard let binding = declaration.bindings.first else {
                throw ErrorDiagnosticMessage(id: "missing-binding", message: "'Renamed' is only supported on variables with at least 1 binding")
            }

            if let accessor = binding.accessor {
                // Could have get/set/_modify
                if accessor.is(CodeBlockSyntax.self) {
                    // This is a "naked" getter, e.g. not `get` or `set`
                    return [immutableProperty]
                }

                guard let accessor = accessor.as(AccessorBlockSyntax.self) else {
                    throw ErrorDiagnosticMessage(id: "unsupported-block", message: "'Renamed' is only supported on variables with block and explicit accessor syntax")
                }

                // TODO: Possible support other accessors, e.g. `_modify`, `willSet`, and `didSet`

                guard accessor.accessors.contains(where: { $0.accessorKind.tokenKind == .keyword(.get) }) else {
                    throw ErrorDiagnosticMessage(id: "missing-get-accessor", message: "'Renamed' is only supported on variables with a getter")
                }

                if accessor.accessors.contains(where: { $0.accessorKind.tokenKind == .keyword(.set) }) {
                    return [mutableProperty]
                } else {
                    return [immutableProperty]
                }
            } else {
                // Not accessor; just a plain `var`.
                return [mutableProperty]
            }
        default:
            throw ErrorDiagnosticMessage(id: "unsupported-variable", message: "'Renamed' is only supported on var and let variables. This is a \(declaration.bindingKeyword)")
        }
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

private protocol ModifiedDeclSyntax: SyntaxProtocol {
    var modifiers: ModifierListSyntax? { get set }
}

extension StructDeclSyntax: ModifiedDeclSyntax {}
extension ClassDeclSyntax: ModifiedDeclSyntax {}
extension EnumDeclSyntax: ModifiedDeclSyntax {}
extension TypealiasDeclSyntax: ModifiedDeclSyntax {}
