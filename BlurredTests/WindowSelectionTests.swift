import XCTest
@testable import Blurred

final class WindowSelectionTests: XCTestCase {

    // MARK: - Helpers

    private func makeWindowInfo(
        number: Int = 1,
        bounds: CGRect = CGRect(x: 0, y: 0, width: 800, height: 600),
        layer: Int = 0,
        ownerName: String? = nil
    ) -> WindowInfo {
        var info = WindowInfo(dict: [
            "kCGWindowAlpha": 1.0,
            "kCGWindowBounds": ["X": bounds.origin.x, "Y": bounds.origin.y, "Width": bounds.width, "Height": bounds.height] as NSDictionary,
            "kCGWindowLayer": layer,
            "kCGWindowNumber": number,
            "kCGWindowOwnerPID": 100,
            "kCGWindowSharingState": 1,
            "kCGWindowStoreType": 1,
            "kCGWindowOwnerName": ownerName as Any,
        ])!
        return info
    }

    // MARK: - cgToNSRect

    func testCGToNS_horizontalSideBySide() {
        let result = WindowSelection.cgToNSRect(CGRect(x: 1920, y: 0, width: 1920, height: 1080), primaryScreenHeight: 1080)
        XCTAssertEqual(result, NSRect(x: 1920, y: 0, width: 1920, height: 1080))
    }

    func testCGToNS_secondaryAbovePrimary() {
        let result = WindowSelection.cgToNSRect(CGRect(x: 0, y: -1080, width: 1920, height: 1080), primaryScreenHeight: 1080)
        XCTAssertEqual(result, NSRect(x: 0, y: 1080, width: 1920, height: 1080))
    }

    func testCGToNS_secondaryLeftOfPrimary() {
        let result = WindowSelection.cgToNSRect(CGRect(x: -1920, y: 0, width: 1920, height: 1080), primaryScreenHeight: 1080)
        XCTAssertEqual(result, NSRect(x: -1920, y: 0, width: 1920, height: 1080))
    }

    func testCGToNS_secondaryBelowPrimary() {
        let result = WindowSelection.cgToNSRect(CGRect(x: 0, y: 1080, width: 1920, height: 1080), primaryScreenHeight: 1080)
        XCTAssertEqual(result, NSRect(x: 0, y: -1080, width: 1920, height: 1080))
    }

    func testCGToNS_mixedScaling() {
        let result = WindowSelection.cgToNSRect(CGRect(x: 1440, y: 0, width: 1920, height: 1080), primaryScreenHeight: 900)
        XCTAssertEqual(result, NSRect(x: 1440, y: -180, width: 1920, height: 1080))
    }

    // MARK: - frontmostWindow

    func testFrontmostWindow_centerInsideScreen() {
        let screen = NSRect(x: 0, y: 0, width: 1920, height: 1080)
        let win = makeWindowInfo(number: 42, bounds: CGRect(x: 100, y: 100, width: 800, height: 600))
        let result = WindowSelection.frontmostWindow(on: screen, from: [win], primaryScreenHeight: 1080)
        XCTAssertEqual(result, 42)
    }

    func testFrontmostWindow_centerOutsideScreen() {
        let screen = NSRect(x: 0, y: 0, width: 1920, height: 1080)
        let win = makeWindowInfo(number: 42, bounds: CGRect(x: 2000, y: 100, width: 800, height: 600))
        let result = WindowSelection.frontmostWindow(on: screen, from: [win], primaryScreenHeight: 1080)
        XCTAssertNil(result)
    }

    func testFrontmostWindow_firstMatchReturned() {
        let screen = NSRect(x: 0, y: 0, width: 1920, height: 1080)
        let win1 = makeWindowInfo(number: 10, bounds: CGRect(x: 100, y: 100, width: 800, height: 600))
        let win2 = makeWindowInfo(number: 20, bounds: CGRect(x: 200, y: 200, width: 800, height: 600))
        let result = WindowSelection.frontmostWindow(on: screen, from: [win1, win2], primaryScreenHeight: 1080)
        XCTAssertEqual(result, 10)
    }

    func testFrontmostWindow_emptyArray() {
        let screen = NSRect(x: 0, y: 0, width: 1920, height: 1080)
        let result = WindowSelection.frontmostWindow(on: screen, from: [], primaryScreenHeight: 1080)
        XCTAssertNil(result)
    }

    func testFrontmostWindow_zeroSizeWindowSkipped() {
        let screen = NSRect(x: 0, y: 0, width: 1920, height: 1080)
        let zeroWin = makeWindowInfo(number: 1, bounds: CGRect(x: 0, y: 0, width: 0, height: 0))
        let normalWin = makeWindowInfo(number: 2, bounds: CGRect(x: 100, y: 100, width: 800, height: 600))
        let result = WindowSelection.frontmostWindow(on: screen, from: [zeroWin, normalWin], primaryScreenHeight: 1080)
        XCTAssertEqual(result, 2)
    }

    // MARK: - isDesktopClick

    func testIsDesktopClick_finderNoWindows() {
        let result = WindowSelection.isDesktopClick(
            bundleIdentifier: "com.apple.finder",
            windowInfos: [],
            screenFrame: NSRect(x: 0, y: 0, width: 1920, height: 1080),
            primaryScreenHeight: 1080
        )
        XCTAssertTrue(result)
    }

    func testIsDesktopClick_finderWindowOnThisScreen() {
        let win = makeWindowInfo(number: 1, bounds: CGRect(x: 100, y: 100, width: 800, height: 600), ownerName: "Finder")
        let result = WindowSelection.isDesktopClick(
            bundleIdentifier: "com.apple.finder",
            windowInfos: [win],
            screenFrame: NSRect(x: 0, y: 0, width: 1920, height: 1080),
            primaryScreenHeight: 1080
        )
        XCTAssertFalse(result)
    }

    func testIsDesktopClick_finderWindowOnOtherScreen() {
        let win = makeWindowInfo(number: 1, bounds: CGRect(x: 2000, y: 100, width: 800, height: 600), ownerName: "Finder")
        let result = WindowSelection.isDesktopClick(
            bundleIdentifier: "com.apple.finder",
            windowInfos: [win],
            screenFrame: NSRect(x: 0, y: 0, width: 1920, height: 1080),
            primaryScreenHeight: 1080
        )
        XCTAssertTrue(result)
    }

    func testIsDesktopClick_nonFinderApp() {
        let result = WindowSelection.isDesktopClick(
            bundleIdentifier: "com.example.app",
            windowInfos: [],
            screenFrame: NSRect(x: 0, y: 0, width: 1920, height: 1080),
            primaryScreenHeight: 1080
        )
        XCTAssertFalse(result)
    }

    func testIsDesktopClick_nilBundleID() {
        let result = WindowSelection.isDesktopClick(
            bundleIdentifier: nil,
            windowInfos: [],
            screenFrame: NSRect(x: 0, y: 0, width: 1920, height: 1080),
            primaryScreenHeight: 1080
        )
        XCTAssertFalse(result)
    }
}
