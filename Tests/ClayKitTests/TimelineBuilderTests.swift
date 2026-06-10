import XCTest
@testable import Clay

final class TimelineBuilderTests: XCTestCase {
    private let theme = WidgetTheme(id: "t", name: "T")

    private func recipe(_ blocks: [BlockInstance]) -> WidgetRecipe {
        WidgetRecipe(name: "Test", blocks: blocks, theme: theme)
    }

    func testDigitalClockOnlyIsSingleLazyEntry() {
        let plan = RecipeTimelineBuilder.plan(
            for: recipe([BlockInstance(kind: .clock)]), now: .now)
        XCTAssertEqual(plan.entryDates.count, 1, "self-updating text needs no extra entries")
        XCTAssertNotNil(plan.reloadAfter, "single-entry timeline must not be .atEnd (immediately stale)")
    }

    func testAnalogClockBatchesMinuteEntriesUnderCap() throws {
        let analog = BlockInstance(
            kind: .clock,
            config: try JSONValue(encoding: ClockConfig(style: "analog")))
        let now = Date()
        let plan = RecipeTimelineBuilder.plan(for: recipe([analog]), now: now)

        XCTAssertEqual(plan.entryDates.count, RecipeTimelineBuilder.maxEntries)
        XCTAssertNil(plan.reloadAfter, "analog batch rides .atEnd")
        // Entries beyond the first are minute-aligned and strictly increasing.
        let calendar = Calendar.current
        for date in plan.entryDates.dropFirst() {
            XCTAssertEqual(calendar.component(.second, from: date), 0)
        }
        XCTAssertEqual(plan.entryDates, plan.entryDates.sorted())
        // Horizon stays ~1h.
        XCTAssertLessThanOrEqual(
            plan.entryDates.last!.timeIntervalSince(now), 3601)
    }

    func testDateBlockGetsMidnightBoundary() {
        let plan = RecipeTimelineBuilder.plan(
            for: recipe([BlockInstance(kind: .date)]), now: .now)
        XCTAssertEqual(plan.entryDates.count, 2, "now + next midnight")
        XCTAssertNil(plan.reloadAfter, "future boundary entries ride .atEnd")

        let midnight = plan.entryDates[1]
        let components = Calendar.current.dateComponents([.hour, .minute], from: midnight)
        XCTAssertEqual(components.hour, 0)
        XCTAssertEqual(components.minute, 0)
    }

    func testMixedNeedsMerge() throws {
        let analog = BlockInstance(
            kind: .clock, config: try JSONValue(encoding: ClockConfig(style: "analog")))
        let date = BlockInstance(kind: .date)
        let plan = RecipeTimelineBuilder.plan(for: recipe([analog, date]), now: .now)
        // Cap still respected with merged needs.
        XCTAssertLessThanOrEqual(plan.entryDates.count, RecipeTimelineBuilder.maxEntries)
        XCTAssertGreaterThan(plan.entryDates.count, 1)
    }

    func testUnknownBlockContributesNothing() {
        let plan = RecipeTimelineBuilder.plan(
            for: recipe([BlockInstance(kind: BlockKind(rawValue: "hologram"))]), now: .now)
        XCTAssertEqual(plan.entryDates.count, 1)
        XCTAssertNotNil(plan.reloadAfter)
    }

    func testSnapshotResolverNeedsUnion() {
        let union = SnapshotResolver.needs(of: recipe([
            BlockInstance(kind: .clock),
            BlockInstance(kind: .date),
            BlockInstance(kind: BlockKind(rawValue: "hologram")),
        ]))
        XCTAssertEqual(union, [.time])
    }
}
