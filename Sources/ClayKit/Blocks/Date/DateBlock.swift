/**
 Date block — weekday/day/month in configurable prominence. One timeline
 entry at the next midnight flips the date.
 */
import SwiftUI
import iUXiOS

public struct DateConfig: Codable, Hashable, Sendable {
    public var showsWeekday: Bool
    public var showsMonth: Bool
    /// "stacked" (weekday over big day numeral) | "inline" (one line).
    public var arrangement: String

    public init(showsWeekday: Bool = true, showsMonth: Bool = true, arrangement: String = "stacked") {
        self.showsWeekday = showsWeekday
        self.showsMonth = showsMonth
        self.arrangement = arrangement
    }

    public var isStacked: Bool { arrangement != "inline" }
}

public enum DateBlock: BlockModule {
    public static let kind = BlockKind.date
    public static let displayName = "Date"
    public static let systemImage = "calendar.circle"
    public static let defaultConfig = DateConfig()
    public static let dataNeeds: Set<DataNeed> = [.time]

    public nonisolated static func timelineNeed(config: DateConfig) -> TimelineNeed {
        let nextMidnight = Calendar.current.nextDate(
            after: .now, matching: DateComponents(hour: 0, minute: 0),
            matchingPolicy: .nextTime) ?? .now.addingTimeInterval(86_400)
        return .at([nextMidnight])
    }

    @MainActor
    public static func render(
        config: DateConfig,
        style: ResolvedBlockStyle,
        snapshot: BlockDataSnapshot,
        context: BlockRenderContext
    ) -> AnyView {
        AnyView(DateBlockView(config: config, style: style, date: snapshot.date, family: context.family))
    }

    @MainActor
    public static func configEditor(config: Binding<DateConfig>) -> AnyView {
        AnyView(DateConfigEditor(config: config))
    }
}

// MARK: - Renderer

private struct DateBlockView: View {
    let config: DateConfig
    let style: ResolvedBlockStyle
    let date: Date
    let family: WidgetFamilyKey

    var body: some View {
        if config.isStacked && !family.isAccessory {
            VStack(spacing: 0) {
                if config.showsWeekday {
                    Text(date, format: .dateTime.weekday(.wide))
                        .font(style.font(size: 13))
                        .foregroundStyle(style.tintColor ?? style.secondaryColor)
                        .textCase(.uppercase)
                }
                Text(date, format: .dateTime.day())
                    .font(style.font(size: 34))
                    .foregroundStyle(style.primaryColor)
                if config.showsMonth {
                    Text(date, format: .dateTime.month(.wide))
                        .font(style.font(size: 13))
                        .foregroundStyle(style.secondaryColor)
                }
            }
            .lineLimit(1)
            .minimumScaleFactor(0.6)
        } else {
            Text(date, format: inlineFormat)
                .font(style.font(size: family.isAccessory ? 15 : 17))
                .foregroundStyle(style.primaryColor)
                .lineLimit(1)
                .minimumScaleFactor(0.6)
        }
    }

    private var inlineFormat: Date.FormatStyle {
        var format = Date.FormatStyle().day()
        if config.showsWeekday { format = format.weekday(.abbreviated) }
        if config.showsMonth { format = format.month(.abbreviated) }
        return format
    }
}

// MARK: - Config editor

private struct DateConfigEditor: View {
    @Binding var config: DateConfig

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            OptionChips(
                options: [("Stacked", "stacked"), ("Inline", "inline")],
                selection: $config.arrangement)
                .padding(.vertical, UX.rowVPadding)
            Divider()
            ToggleRow("Weekday", isOn: $config.showsWeekday)
            Divider()
            ToggleRow("Month", isOn: $config.showsMonth)
        }
    }
}
