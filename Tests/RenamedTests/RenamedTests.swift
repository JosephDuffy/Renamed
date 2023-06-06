import RenamedPlugin
import SwiftSyntaxMacros
import SwiftSyntaxMacrosTestSupport
import XCTest

private let testMacros: [String: Macro.Type] = [
    "Renamed": Renamed.self,
]

final class RenamedTests: XCTestCase {
    func testTypealiasForStruct() {
        assertMacroExpansion(
            """
            @Renamed(from: "OldStruct")
            private struct RenamedStruct {}
            """,
            expandedSource: """

            private struct RenamedStruct {
            }
            @available(*, deprecated, renamed: "RenamedStruct")
            private typealias OldStruct = RenamedStruct
            """,
            macros: testMacros
        )
    }

    func testTypealiasForClass() {
        assertMacroExpansion(
            """
            @Renamed(from: "OldClass")
            final class RenamedClass {}
            """,
            expandedSource: """

            final class RenamedClass {
            }
            @available(*, deprecated, renamed: "RenamedClass")
            typealias OldClass = RenamedClass
            """,
            macros: testMacros
        )
    }

    func testTypealiasForEnum() {
        assertMacroExpansion(
            """
            @Renamed(from: "OldEnum")
            enum RenamedEnum {}
            """,
            expandedSource: """

            enum RenamedEnum {
            }
            @available(*, deprecated, renamed: "RenamedEnum")
            typealias OldEnum = RenamedEnum
            """,
            macros: testMacros
        )
    }

    func testTypealiasForTypealias() {
        assertMacroExpansion(
            """
            @Renamed(from: "OldTypealias")
            public typealias RenamedTypealias = String
            """,
            expandedSource: """

            public typealias RenamedTypealias = String
            @available(*, deprecated, renamed: "RenamedTypealias")
            public typealias OldTypealias = RenamedTypealias
            """,
            macros: testMacros
        )
    }

    func testRenamedProperties() {
        // The output shows how some of the indentation, especially when scopes are provides, does
        // not match the surrounding code. This could be improved but isn't necessary for the
        // function of the macro.
        assertMacroExpansion(
            """
            struct TestStruct {
                @Renamed(from: "oldImmutableProperty")
                let immutableProperty: String

                @Renamed(from: "oldMutableProperty")
                var mutableProperty: String

                @Renamed(from: "oldComputedImmutableProperty")
                var computedImmutableProperty: String {
                    _computedImmutableProperty
                }

                private let _computedImmutableProperty: String

                @Renamed(from: "oldComputedMutableProperty")
                var computedMutableProperty: String {
                    get {
                        _computedMutableProperty
                    }
                    set {
                        _computedMutableProperty = newValue
                    }
                }

                private var _computedMutableProperty: String

                init(immutableProperty: String, mutableProperty: String, computedImmutableProperty: String, computedMutableProperty: String) {
                    self.immutableProperty = immutableProperty
                    self.mutableProperty = mutableProperty
                    _computedImmutableProperty = computedImmutableProperty
                    _computedMutableProperty = computedMutableProperty
                }

                @Renamed(from: "oldTestFunction(_:oldArgumentLabel:_:oldTrailingClosure)")
                public func testFunction(_ unnamedParameter: String, argumentLabel parameterName: Int, previouslyUnnamed: Bool, trailingClosure: @escaping () -> Void) -> Bool {
                    true
                }

                @Renamed(from: "oldTestFunctionWithoutReturn")
                func testFunctionWithoutReturn() {}
            }
            """,
            expandedSource: """
            struct TestStruct {
                let immutableProperty: String
                @available(*, deprecated, renamed: "immutableProperty")
                var oldImmutableProperty: String {
                    immutableProperty
                }
                var mutableProperty: String
                @available(*, deprecated, renamed: "mutableProperty")
                var oldMutableProperty: String {
                    get {
                        mutableProperty
                    }
                    set {
                        mutableProperty = newValue
                    }
                }
                var computedImmutableProperty: String {
                    _computedImmutableProperty
                }
                @available(*, deprecated, renamed: "computedImmutableProperty")
                var oldComputedImmutableProperty: String  {
                    computedImmutableProperty
                }

                private let _computedImmutableProperty: String
                var computedMutableProperty: String {
                    get {
                        _computedMutableProperty
                    }
                    set {
                        _computedMutableProperty = newValue
                    }
                }
                @available(*, deprecated, renamed: "computedMutableProperty")
                var oldComputedMutableProperty: String  {
                    get {
                        computedMutableProperty
                    }
                    set {
                        computedMutableProperty = newValue
                    }
                }

                private var _computedMutableProperty: String

                init(immutableProperty: String, mutableProperty: String, computedImmutableProperty: String, computedMutableProperty: String) {
                    self.immutableProperty = immutableProperty
                    self.mutableProperty = mutableProperty
                    _computedImmutableProperty = computedImmutableProperty
                    _computedMutableProperty = computedMutableProperty
                }
                public func testFunction(_ unnamedParameter: String, argumentLabel parameterName: Int, previouslyUnnamed: Bool, trailingClosure: @escaping () -> Void) -> Bool {
                    true
                }
                @available(*, deprecated, renamed: "testFunction(_:argumentLabel:previouslyUnnamed:trailingClosure:)")

                    public func oldTestFunction(_ arg0: String, oldArgumentLabel arg1: Int, _ arg2: Bool, oldTrailingClosure arg3: @escaping () -> Void) -> Bool {
                    testFunction(arg0, argumentLabel : arg1, previouslyUnnamed: arg2, trailingClosure: arg3)
                }
                func testFunctionWithoutReturn() {
                }
                @available(*, deprecated, renamed: "testFunctionWithoutReturn")
                func oldTestFunctionWithoutReturn() {
                    testFunctionWithoutReturn()
                }
            }
            """,
            macros: testMacros
        )
    }
}
