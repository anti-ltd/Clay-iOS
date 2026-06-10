/**
 `BlockDataSnapshot`: every piece of runtime data a recipe's blocks consume,
 resolved BEFORE rendering — in-app by a live ticker, in-extension by the
 timeline provider. Renderers are pure functions of (config, style, snapshot):
 they never call `Date()`, never touch a framework data source, never await.
 That invariant is what makes the in-app preview pixel-truthful.
 */
import Foundation

public enum DataNeed: String, Codable, CaseIterable, Sendable {
    case time
    case battery
    case weather
    case photos
    case events
    case steps
}

public struct BatterySnapshot: Codable, Hashable, Sendable {
    /// 0…1
    public var level: Double
    public var isCharging: Bool

    public init(level: Double, isCharging: Bool) {
        self.level = level
        self.isCharging = isCharging
    }
}

public struct WeatherSnapshot: Codable, Hashable, Sendable {
    /// Celsius; renderers format per locale.
    public var temperature: Double
    public var highTemperature: Double
    public var lowTemperature: Double
    /// SF Symbol from WeatherKit's condition mapping.
    public var symbolName: String
    public var conditionDescription: String
    public var asOf: Date

    public init(
        temperature: Double, highTemperature: Double, lowTemperature: Double,
        symbolName: String, conditionDescription: String, asOf: Date
    ) {
        self.temperature = temperature
        self.highTemperature = highTemperature
        self.lowTemperature = lowTemperature
        self.symbolName = symbolName
        self.conditionDescription = conditionDescription
        self.asOf = asOf
    }
}

public struct EventSnapshot: Codable, Hashable, Sendable, Identifiable {
    public var id: String
    public var title: String
    public var start: Date
    public var end: Date
    public var isAllDay: Bool
    public var calendarColor: RGBA

    public init(id: String, title: String, start: Date, end: Date, isAllDay: Bool, calendarColor: RGBA) {
        self.id = id
        self.title = title
        self.start = start
        self.end = end
        self.isAllDay = isAllDay
        self.calendarColor = calendarColor
    }
}

public struct StepsSnapshot: Codable, Hashable, Sendable {
    public var count: Int
    public var goal: Int
    public var asOf: Date

    public init(count: Int, goal: Int, asOf: Date) {
        self.count = count
        self.goal = goal
        self.asOf = asOf
    }
}

public struct QuoteSnapshot: Codable, Hashable, Sendable {
    public var text: String
    public var attribution: String?

    public init(text: String, attribution: String? = nil) {
        self.text = text
        self.attribution = attribution
    }
}

public struct BlockDataSnapshot: Codable, Hashable, Sendable {
    /// The timeline entry date. THE clock for every block — renderers never
    /// call `Date()`.
    public var date: Date
    public var battery: BatterySnapshot?
    public var weather: WeatherSnapshot?
    public var events: [EventSnapshot]
    public var steps: StepsSnapshot?
    /// Photo-block instance id → filename chosen for THIS entry (shuffle picks
    /// per entry; single always the same).
    public var photoSelection: [UUID: String]
    /// Quote-block instance id → quote chosen for THIS entry.
    public var quoteSelection: [UUID: QuoteSnapshot]
    /// Needs whose permission is denied/undetermined — drives the in-widget
    /// "tap to enable" placeholder instead of a blank block.
    public var deniedNeeds: Set<DataNeed>

    public init(
        date: Date,
        battery: BatterySnapshot? = nil,
        weather: WeatherSnapshot? = nil,
        events: [EventSnapshot] = [],
        steps: StepsSnapshot? = nil,
        photoSelection: [UUID: String] = [:],
        quoteSelection: [UUID: QuoteSnapshot] = [:],
        deniedNeeds: Set<DataNeed> = []
    ) {
        self.date = date
        self.battery = battery
        self.weather = weather
        self.events = events
        self.steps = steps
        self.photoSelection = photoSelection
        self.quoteSelection = quoteSelection
        self.deniedNeeds = deniedNeeds
    }

    /// Canned, attractive data for the editor's block gallery, widget gallery
    /// placeholders, and WidgetKit's `placeholder(in:)`.
    public static func placeholder(date: Date = .now) -> BlockDataSnapshot {
        BlockDataSnapshot(
            date: date,
            battery: BatterySnapshot(level: 0.82, isCharging: false),
            weather: WeatherSnapshot(
                temperature: 21, highTemperature: 24, lowTemperature: 14,
                symbolName: "sun.max.fill", conditionDescription: "Sunny", asOf: date),
            events: [
                EventSnapshot(
                    id: "placeholder-1", title: "Design review",
                    start: date.addingTimeInterval(45 * 60),
                    end: date.addingTimeInterval(105 * 60),
                    isAllDay: false, calendarColor: RGBA(hex: 0x6D8FFB)),
            ],
            steps: StepsSnapshot(count: 6243, goal: 10_000, asOf: date))
    }
}
