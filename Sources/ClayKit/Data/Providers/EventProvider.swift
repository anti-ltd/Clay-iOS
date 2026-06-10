/**
 EventKit provider: the next 24h of events, permission-aware. Denied or
 undetermined access lands `.events` in `deniedNeeds`, which the recipe view
 turns into the "tap to enable" block.
 */
import EventKit

public struct EventProvider: SnapshotProviding {
    public let need = DataNeed.events

    public init() {}

    public func contribute(
        to snapshot: inout BlockDataSnapshot, recipe: WidgetRecipe, at date: Date
    ) async {
        guard EKEventStore.authorizationStatus(for: .event) == .fullAccess else {
            snapshot.deniedNeeds.insert(.events)
            return
        }

        let store = EKEventStore()
        let predicate = store.predicateForEvents(
            withStart: date,
            end: date.addingTimeInterval(24 * 3600),
            calendars: nil)
        let events = store.events(matching: predicate)
            .filter { !$0.isAllDay || Calendar.current.isDate($0.startDate, inSameDayAs: date) }
            .sorted { $0.startDate < $1.startDate }
            .prefix(10)

        snapshot.events = events.map { event in
            EventSnapshot(
                id: event.eventIdentifier ?? UUID().uuidString,
                title: event.title ?? "Event",
                start: event.startDate,
                end: event.endDate,
                isAllDay: event.isAllDay,
                calendarColor: event.calendar.map { RGBA(Color($0.cgColor)) }
                    ?? RGBA(hex: 0x6D8FFB))
        }
    }
}

import SwiftUI

private extension Color {
    init(_ cgColor: CGColor) {
        self.init(uiColor: UIColor(cgColor: cgColor))
    }
}
