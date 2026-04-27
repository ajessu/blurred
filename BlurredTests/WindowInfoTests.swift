import XCTest
@testable import Blurred

final class WindowInfoTests: XCTestCase {

    private func completeDict(overrides: [String: Any] = [:]) -> [String: Any] {
        var dict: [String: Any] = [
            "kCGWindowAlpha": 1.0,
            "kCGWindowBounds": ["X": 0, "Y": 0, "Width": 800, "Height": 600] as NSDictionary,
            "kCGWindowLayer": 0,
            "kCGWindowNumber": 42,
            "kCGWindowOwnerPID": 1234,
            "kCGWindowSharingState": 1,
            "kCGWindowStoreType": 1,
        ]
        for (k, v) in overrides { dict[k] = v }
        return dict
    }

    func testCompleteDict_returnsWindowInfo() {
        let info = WindowInfo(dict: completeDict())
        XCTAssertNotNil(info)
        XCTAssertEqual(info?.number, 42)
        XCTAssertEqual(info?.layer, 0)
        XCTAssertEqual(info?.alpha, 1.0)
        XCTAssertEqual(info?.bounds, CGRect(x: 0, y: 0, width: 800, height: 600))
    }

    func testMissingWindowNumber_returnsNil() {
        var dict = completeDict()
        dict.removeValue(forKey: "kCGWindowNumber")
        XCTAssertNil(WindowInfo(dict: dict))
    }

    func testMissingLayer_returnsNil() {
        var dict = completeDict()
        dict.removeValue(forKey: "kCGWindowLayer")
        XCTAssertNil(WindowInfo(dict: dict))
    }

    func testMissingBounds_returnsNil() {
        var dict = completeDict()
        dict.removeValue(forKey: "kCGWindowBounds")
        XCTAssertNil(WindowInfo(dict: dict))
    }

    func testOptionalFieldsMissing_returnsNonNil() {
        let info = WindowInfo(dict: completeDict())
        XCTAssertNotNil(info)
        XCTAssertNil(info?.name)
        XCTAssertNil(info?.ownerName)
        XCTAssertNil(info?.isOnScreen)
        XCTAssertNil(info?.backingLocationVideoMemory)
    }

    func testOptionalFieldsPresent_populatedCorrectly() {
        let info = WindowInfo(dict: completeDict(overrides: [
            "kCGWindowName": "Test Window",
            "kCGWindowOwnerName": "TestApp",
            "kCGWindowIsOnscreen": true,
        ]))
        XCTAssertEqual(info?.name, "Test Window")
        XCTAssertEqual(info?.ownerName, "TestApp")
        XCTAssertEqual(info?.isOnScreen, true)
    }

    func testMissingMemoryUsage_defaultsToZero() {
        let info = WindowInfo(dict: completeDict())
        XCTAssertEqual(info?.memoryUsage, 0)
    }
}
