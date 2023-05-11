import XCTest
import Renamed

final class RenamedTests: XCTestCase {
    func testTypealiasForStruct() {
        _ = OldStruct.self
    }

    func testTypealiasForClass() {
        _ = OldClass.self
    }
}

@Renamed(from: "OldStruct")
private struct RenamedStruct {}

@Renamed(from: "OldClass")
private final class RenamedClass {}