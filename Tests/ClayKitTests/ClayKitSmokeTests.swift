import XCTest
@testable import Clay

final class ClayKitSmokeTests: XCTestCase {
    func testAppGroupConstant() {
        XCTAssertEqual(ClayKit.appGroupID, "group.ltd.anti.clay")
    }
}
