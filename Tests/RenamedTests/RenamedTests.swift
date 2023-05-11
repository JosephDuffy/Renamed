import XCTest
import Renamed

final class RenamedTests: XCTestCase {
    func testTypealiasForStruct() {
        _ = OldStruct.self
    }

    func testTypealiasForClass() {
        _ = OldClass.self
    }

    func testRenamedProperties() {
        let value = "test-value"
        let testStruct = TestStruct(immutableProperty: value)
        XCTAssertEqual(testStruct.oldImmutableProperty, value)
    }
}

@Renamed(from: "OldStruct")
private struct RenamedStruct {}

@Renamed(from: "OldClass")
private final class RenamedClass {}

private struct TestStruct {
    @Renamed(from: "oldImmutableProperty")
    let immutableProperty: String
}