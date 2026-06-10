/**
 Countdown block — rides iUX's widget-safe `CountdownText` (`Text(timerInterval:)`
 ticks client-side, zero timeline cost). One boundary entry at the target date
 flips to the "done" state.
 */
import SwiftUI
import iUXiOS

public struct CountdownConfig: Codable, Hashable, Sendable {
    public var label: String
    public var targetDate: Date
    public var style: String      // "timer" | "relative"

    public init(
        label: String = "New Year",
        targetDate: Date = Calendar.current.nextDate(
            after: .now, matching: DateComponents(month: 1, day: 1),
            matchingPolicy: .nextTime) ?? .now.addingTimeInterval(86_400 * 30),
        style: String = "timer"
    ) {
        self.label = label
        self.targetDate = targetDate
        self.style = style
    }
}

public enum CountdownBlock: BlockModule {
    public static let kind = BlockKind.countdown
    public static let displayName = "Countdown"
    public static let systemImage = "timer"
    public static let defaultConfig = CountdownConfig()
    public static let dataNeeds: Set<DataNeed> = [.time]

    public nonisolated static func timelineNeed(config: CountdownConfig) -> TimelineNeed {
        // Self-updating text does the ticking; one boundary flips to "done".
        config.targetDate > .now ? .at([config.targetDate]) : .staticEntry
    }

    @MainActor
    public static func render(
        config: CountdownConfig,
        style: ResolvedBlockStyle,
        snapshot: BlockDataSnapshot,
        context: BlockRenderContext
    ) -> AnyView {
        AnyView(CountdownBlockView(
            config: config, style: style, date: snapshot.date, family: context.family))
    }

    @MainActor
    public static func configEditor(config: Binding<CountdownConfig>) -> AnyView {
        AnyView(CountdownConfigEditor(config: config))
    }
}

private struct CountdownBlockView: View {
    let config: CountdownConfig
    let style: ResolvedBlockStyle
    let date: Date
    let family: WidgetFamilyKey

    var body: some View {
        VStack(spacing: 2) {
            if !config.label.isEmpty && family != .accessoryCircular {
                Text(config.label)
                    .font(style.font(size: 12))
                    .foregroundStyle(style.tintColor ?? style.secondaryColor)
                    .textCase(.uppercase)
                    .lineLimit(1)
            }
            if config.targetDate > date {
                CountdownText(
                    from: date,
                    until: config.targetDate,
                    style: config.style == "relative" ? .relative : .timer)
                    .font(style.font(size: family.isAccessory ? 16 : 24))
                    .foregroundStyle(style.primaryColor)
                    .lineLimit(1)
                    .minimumScaleFactor(0.5)
            } else {
                Label("Done", systemImage: "checkmark.circle.fill")
                    .font(style.font(size: family.isAccessory ? 14 : 18))
                    .foregroundStyle(style.tintColor ?? style.primaryColor)
            }
        }
    }
}

private struct CountdownConfigEditor: View {
    @Binding var config: CountdownConfig

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            TextFieldRow("Label", prompt: "What are you counting down to?", text: $config.label)
            Divider()
            DatePicker(
                "Date",
                selection: $config.targetDate,
                in: Date.now...,
                displayedComponents: [.date, .hourAndMinute])
                .padding(.vertical, UX.rowVPadding)
            Divider()
            OptionChips(
                options: [("Timer", "timer"), ("Relative", "relative")],
                selection: $config.style)
                .padding(.vertical, UX.rowVPadding)
        }
    }
}
