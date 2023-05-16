import XCTest
import Renamed

final class RenamedTests: XCTestCase {
    func testTypealiasForStruct() {
        XCTAssertTrue(OldStruct.self == RenamedStruct.self)
    }

    func testTypealiasForClass() {
        XCTAssertTrue(OldClass.self == RenamedClass.self)
    }

    func testRenamedProperties() {
        let immutablePropertyValue = "test-value"
        let initialMutablePropertyValue = "first-value"
        let updatedMutablePropertyValue = "second-value"
        let computedImmutablePropertyValue = "computed"
        let initialComputedMutablePropertyValue = "first-computed-value"
        let updatedComputedMutablePropertyValue = "second-computed-value"
        var testStruct = TestStruct(
            immutableProperty: immutablePropertyValue,
            mutableProperty: initialMutablePropertyValue,
            computedImmutableProperty: computedImmutablePropertyValue,
            computedMutableProperty: initialComputedMutablePropertyValue
        )

        XCTAssertEqual(testStruct.oldImmutableProperty, immutablePropertyValue)
        XCTAssertEqual(testStruct.oldMutableProperty, initialMutablePropertyValue)

        testStruct.oldMutableProperty = updatedMutablePropertyValue
        XCTAssertEqual(testStruct.oldMutableProperty, updatedMutablePropertyValue)

        XCTAssertEqual(testStruct.oldComputedImmutableProperty, computedImmutablePropertyValue)

        testStruct.oldComputedMutableProperty = updatedComputedMutablePropertyValue
        XCTAssertEqual(testStruct.oldComputedMutableProperty, updatedComputedMutablePropertyValue)
    }
}

@Renamed(from: "OldStruct")
private struct RenamedStruct {}

@Renamed(from: "OldClass")
private final class RenamedClass {}

private struct TestStruct {
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
}