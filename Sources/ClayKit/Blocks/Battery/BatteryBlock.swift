/**
 Battery block — ring gauge or inline percent. Honest limitation: widgets
 can't observe battery, so the level is sampled when the timeline reloads;
 the editor copy says so.
 */
import SwiftUI
import iUXiOS

public struct BatteryConfig: Codable, Hashable, Sendable {
    public var style: String        // "ring" | "inline"
    public var showsPercent: Bool

    public init(style: String = "ring", showsPercent: Bool = true) {
        self.style = style
        self.showsPercent = showsPercent
    }

    public var isRing: Bool { style != "inline" }
}

public enum BatteryBlock: BlockModule {
    public static let kind = BlockKind.battery
    public static let displayName = "Battery"
    public static let systemImage = "battery.75percent"
    public static let defaultConfig = BatteryConfig()
    public static let dataNeeds: Set<DataNeed> = [.battery]

    @MainActor
    public static func render(
        config: BatteryConfig,
        style: ResolvedBlockStyle,
        snapshot: BlockDataSnapshot,
        context: BlockRenderContext
    ) -> AnyView {
        AnyView(BatteryBlockView(
            config: config, style: style,
            battery: snapshot.battery ?? BatterySnapshot(level: 1, isCharging: false),
            family: context.family))
    }

    @MainActor
    public static func configEditor(config: Binding<BatteryConfig>) -> AnyView {
        AnyView(BatteryConfigEditor(config: config))
    }
}

private struct BatteryBlockView: View {
    let config: BatteryConfig
    let style: ResolvedBlockStyle
    let battery: BatterySnapshot
    let family: WidgetFamilyKey

    private var accent: Color {
        if battery.isCharging { return .green }
        if battery.level <= 0.2 { return .red }
        return style.tintColor ?? style.primaryColor
    }

    var body: some View {
        if config.isRing && family != .accessoryInline {
            ZStack {
                Circle()
                    .stroke(style.secondaryColor.opacity(0.35), lineWidth: 5)
                Circle()
                    .trim(from: 0, to: max(0.02, battery.level))
                    .stroke(accent, style: StrokeStyle(lineWidth: 5, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                VStack(spacing: 0) {
                    if battery.isCharging {
                        Image(systemName: "bolt.fill")
                            .font(.system(size: 9, weight: .bold))
                            .foregroundStyle(accent)
                    }
                    if config.showsPercent {
                        Text("\(Int(battery.level * 100))")
                            .font(style.font(size: 16))
                            .foregroundStyle(style.primaryColor)
                    }
                }
            }
            .aspectRatio(1, contentMode: .fit)
            .padding(3)
        } else {
            HStack(spacing: 4) {
                Image(systemName: battery.isCharging ? "battery.100percent.bolt" : "battery.75percent")
                    .foregroundStyle(accent)
                if config.showsPercent {
                    Text("\(Int(battery.level * 100))%")
                        .font(style.font(size: 15))
                        .foregroundStyle(style.primaryColor)
                }
            }
        }
    }
}

private struct BatteryConfigEditor: View {
    @Binding var config: BatteryConfig

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            OptionChips(
                options: [("Ring", "ring"), ("Inline", "inline")],
                selection: $config.style)
                .padding(.vertical, UX.rowVPadding)
            Divider()
            ToggleRow(
                "Percent",
                subtitle: "Level updates when the widget refreshes.",
                isOn: $config.showsPercent)
        }
    }
}
