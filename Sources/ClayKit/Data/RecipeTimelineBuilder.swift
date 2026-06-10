/**
 `RecipeTimelineBuilder`: merges every block's `TimelineNeed` into one
 budget-respecting entry plan. Pure and synchronous so it unit-tests without
 WidgetKit.

 Merge rules:
 - entry dates = now ∪ per-minute grid ∪ `.at` boundaries ∪ `.every` grids,
   clipped to the horizon, capped at `maxEntries`
 - horizon: 1h when any block needs per-minute entries (the batch is the
   budget win), else 24h
 - reload: `.after(shortest periodic interval)` when any block is periodic;
   `.atEnd` when the timeline has future entries; otherwise a lazy 4h
   re-plan so a single-entry timeline isn't immediately reload-eligible.
 */
import Foundation

public enum RecipeTimelineBuilder {
    public static let maxEntries = 60

    public struct Plan: Equatable, Sendable {
        public var entryDates: [Date]
        /// `nil` = use `.atEnd`; otherwise `.after(reloadAfter)`.
        public var reloadAfter: Date?
    }

    public static func plan(for recipe: WidgetRecipe, now: Date = .now) -> Plan {
        let needs = recipe.blocks.compactMap { instance in
            BlockRegistry.module(for: instance.kind)?.timelineNeed(instance: instance)
        }

        let wantsPerMinute = needs.contains(.perMinute)
        let horizon: TimeInterval = wantsPerMinute ? 3600 : 86_400
        let end = now.addingTimeInterval(horizon)

        var dates: Set<Date> = [now]

        if wantsPerMinute {
            // Minute-aligned grid so the analog clock flips on the minute.
            let calendar = Calendar.current
            var tick = calendar.nextDate(
                after: now, matching: DateComponents(second: 0),
                matchingPolicy: .nextTime) ?? now.addingTimeInterval(60)
            while tick <= end {
                dates.insert(tick)
                tick = tick.addingTimeInterval(60)
            }
        }

        var shortestInterval: TimeInterval?
        for need in needs {
            switch need {
            case .staticEntry, .selfUpdatingText, .perMinute:
                break
            case .at(let boundaries):
                for boundary in boundaries where boundary > now && boundary <= end {
                    dates.insert(boundary)
                }
            case .every(let interval):
                shortestInterval = min(shortestInterval ?? interval, interval)
                var tick = now.addingTimeInterval(interval)
                while tick <= end {
                    dates.insert(tick)
                    tick = tick.addingTimeInterval(interval)
                }
            }
        }

        let sorted = Array(dates.sorted().prefix(maxEntries))

        let reloadAfter: Date?
        if let shortestInterval {
            reloadAfter = now.addingTimeInterval(shortestInterval)
        } else if sorted.count > 1 {
            reloadAfter = nil // .atEnd — WidgetKit re-plans when entries run out.
        } else {
            reloadAfter = now.addingTimeInterval(4 * 3600)
        }

        return Plan(entryDates: sorted, reloadAfter: reloadAfter)
    }
}
