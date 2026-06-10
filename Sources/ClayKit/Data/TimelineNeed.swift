/**
 `TimelineNeed`: the refresh cadence a block requires from WidgetKit, given its
 config. The timeline builder merges the needs of every block in a recipe into
 one budget-respecting entry plan.
 */
import Foundation

public enum TimelineNeed: Hashable, Sendable {
    /// One entry, never refresh on the block's account (photo single, static quote).
    case staticEntry
    /// Text self-updates client-side via `Text(_, style:)` / `Text(timerInterval:)`
    /// — one entry suffices, zero refresh cost (digital clock, countdown).
    case selfUpdatingText
    /// Dated entry per minute (analog clock hands are drawn geometry).
    case perMinute
    /// Fresh entry every interval (weather, steps, photo shuffle, daily quote).
    case every(TimeInterval)
    /// Entries at exact boundaries (date block at midnight, calendar at event
    /// starts/ends).
    case at([Date])
}

/// Describes the system permission a gated block needs, for both the in-app
/// request flow and the in-widget "tap to enable" placeholder.
public struct PermissionRequirement: Hashable, Sendable {
    public let need: DataNeed
    /// "Calendar access"
    public let title: String
    /// One-sentence pitch shown before the system prompt.
    public let explanation: String
    /// SF Symbol for placeholder/pitch chrome.
    public let symbolName: String

    public init(need: DataNeed, title: String, explanation: String, symbolName: String) {
        self.need = need
        self.title = title
        self.explanation = explanation
        self.symbolName = symbolName
    }

    /// The widget placeholder's tap target: routes to the in-app request flow.
    public var deepLink: URL { DeepLink.enable(need.rawValue).url }
}
