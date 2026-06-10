/**
 Calendar block — the next events from EventKit. Snapshot-fed: the provider
 fetches; the renderer lists. Granted-but-empty shows its own quiet empty
 state, distinct from the permission placeholder.
 */
import SwiftUI
import iUXiOS

public struct CalendarConfig: Codable, Hashable, Sendable {
    public var maxEvents: Int
    public var showsTime: Bool

    public init(maxEvents: Int = 3, showsTime: Bool = true) {
        self.maxEvents = maxEvents
        self.showsTime = showsTime
    }
}

public enum CalendarBlock: BlockModule {
    public static let kind = BlockKind.calendar
    public static let displayName = "Calendar"
    public static let systemImage = "calendar"
    public static let defaultConfig = CalendarConfig()
    public static let dataNeeds: Set<DataNeed> = [.events]
    public static let supportedFamilies: Set<WidgetFamilyKey> =
        [.small, .medium, .large, .accessoryRectangular]
    public static let permission = PermissionRequirement(
        need: .events,
        title: "Calendar",
        explanation: "Clay shows your upcoming events on calendar widgets you design.",
        symbolName: "calendar.badge.checkmark")

    public nonisolated static func timelineNeed(config: CalendarConfig) -> TimelineNeed {
        // Real boundaries come from the resolved events; the builder also gets
        // a periodic floor so stale event lists refresh even without edits.
        .every(30 * 60)
    }

    @MainActor
    public static func render(
        config: CalendarConfig,
        style: ResolvedBlockStyle,
        snapshot: BlockDataSnapshot,
        context: BlockRenderContext
    ) -> AnyView {
        AnyView(CalendarBlockView(
            config: config, style: style,
            events: Array(snapshot.events.prefix(config.maxEvents)),
            family: context.family))
    }

    @MainActor
    public static func configEditor(config: Binding<CalendarConfig>) -> AnyView {
        AnyView(CalendarConfigEditor(config: config))
    }
}

private struct CalendarBlockView: View {
    let config: CalendarConfig
    let style: ResolvedBlockStyle
    let events: [EventSnapshot]
    let family: WidgetFamilyKey

    var body: some View {
        if events.isEmpty {
            VStack(spacing: 3) {
                Image(systemName: "calendar")
                    .font(.system(size: 16, weight: .light))
                Text("All clear")
                    .font(style.font(size: 12))
            }
            .foregroundStyle(style.secondaryColor)
        } else {
            VStack(alignment: .leading, spacing: family == .large ? 8 : 5) {
                ForEach(events) { event in
                    HStack(spacing: 6) {
                        Capsule()
                            .fill(event.calendarColor.color)
                            .frame(width: 3)
                        VStack(alignment: .leading, spacing: 0) {
                            Text(event.title)
                                .font(style.font(size: 13))
                                .foregroundStyle(style.primaryColor)
                                .lineLimit(1)
                            if config.showsTime && !event.isAllDay {
                                Text(event.start, style: .time)
                                    .font(style.font(size: 10))
                                    .foregroundStyle(style.secondaryColor)
                            }
                        }
                    }
                    .fixedSize(horizontal: false, vertical: true)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}

private struct CalendarConfigEditor: View {
    @Binding var config: CalendarConfig

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Text("Events")
                Spacer()
                ThemedStepper(value: $config.maxEvents, in: 1...5)
            }
            .padding(.vertical, UX.rowVPadding)
            Divider()
            ToggleRow("Times", isOn: $config.showsTime)
        }
    }
}
