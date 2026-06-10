import XCTest
@testable import Clay

final class BlockRegistryTests: XCTestCase {
    func testRegisteredKindsResolve() {
        XCTAssertNotNil(BlockRegistry.module(for: .clock))
        XCTAssertNotNil(BlockRegistry.module(for: .date))
    }

    func testUnknownKindReturnsNilNotCrash() {
        XCTAssertNil(BlockRegistry.module(for: BlockKind(rawValue: "hologram")))
    }

    func testRegistryHasNoDuplicateKinds() {
        let kinds = BlockRegistry.all.map { $0.kind }
        XCTAssertEqual(kinds.count, Set(kinds).count)
    }

    func testTimelineNeeds() {
        // Digital clock rides free on self-updating text; analog needs minutes.
        XCTAssertEqual(
            ClockBlock.timelineNeed(config: ClockConfig(style: "digital")),
            .selfUpdatingText)
        XCTAssertEqual(
            ClockBlock.timelineNeed(config: ClockConfig(style: "analog")),
            .perMinute)

        // Date block wants exactly one boundary: the next midnight.
        guard case .at(let dates) = DateBlock.timelineNeed(config: DateConfig()) else {
            return XCTFail("expected .at")
        }
        XCTAssertEqual(dates.count, 1)
        XCTAssertGreaterThan(dates[0], .now)
    }

    func testErasedConfigBridging() throws {
        let handle = try XCTUnwrap(BlockRegistry.module(for: .clock))

        // A malformed config decodes to the default rather than failing.
        let instance = BlockInstance(kind: .clock, config: .string("garbage"))
        XCTAssertEqual(handle.timelineNeed(instance: instance), .selfUpdatingText)

        // A valid config flows through the erased face.
        let analog = BlockInstance(
            kind: .clock,
            config: try JSONValue(encoding: ClockConfig(style: "analog")))
        XCTAssertEqual(handle.timelineNeed(instance: analog), .perMinute)
    }
}
