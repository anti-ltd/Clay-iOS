/**
 `WidgetFamilyKey`: our own Codable mirror of `WidgetFamily` so the model layer
 doesn't import WidgetKit, plus the point-size table that makes the in-app
 preview pixel-truthful.
 */
import Foundation

public enum WidgetFamilyKey: String, Codable, CaseIterable, Sendable {
    case small
    case medium
    case large
    case accessoryRectangular
    case accessoryCircular
    case accessoryInline

    public var isAccessory: Bool {
        switch self {
        case .small, .medium, .large: false
        case .accessoryRectangular, .accessoryCircular, .accessoryInline: true
        }
    }

    public var displayName: String {
        switch self {
        case .small: "Small"
        case .medium: "Medium"
        case .large: "Large"
        case .accessoryRectangular: "Lock Rect"
        case .accessoryCircular: "Lock Circle"
        case .accessoryInline: "Lock Inline"
        }
    }
}

/// Real widget point sizes per device class, so the editor preview frame
/// matches what WidgetKit will render. Values from Apple's HIG widget
/// size tables.
public enum WidgetFamilyMetrics {
    /// Size for the 393pt-wide device class (iPhone 15/16/17 Pro) — the
    /// design baseline. Other devices scale within a few points.
    public static func pointSize(for family: WidgetFamilyKey) -> CGSize {
        switch family {
        case .small: CGSize(width: 170, height: 170)
        case .medium: CGSize(width: 364, height: 170)
        case .large: CGSize(width: 364, height: 382)
        case .accessoryRectangular: CGSize(width: 160, height: 72)
        case .accessoryCircular: CGSize(width: 72, height: 72)
        case .accessoryInline: CGSize(width: 234, height: 26)
        }
    }
}
