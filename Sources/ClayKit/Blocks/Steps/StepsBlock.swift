/**
 Steps block — today's HealthKit step count against a goal ring. The provider
 caches the last reading in the App Group because HealthKit reads fail while
 the device is locked (exactly when lock-screen widgets refresh).
 */
import SwiftUI
import iUXiOS

public struct StepsConfig: Codable, Hashable, Sendable {
    public var goal: Int
    public var style: String     // "ring" | "count"

    public init(goal: Int = 10_000, style: String = "ring") {
        self.goal = goal
        self.style = style
    }

    public var isRing: Bool { style != "count" }
}

public enum StepsBlock: BlockModule {
    public static let kind = BlockKind.steps
    public static let displayName = "Steps"
    public static let systemImage = "figure.walk"
    public static let defaultConfig = StepsConfig()
    public static let dataNeeds: Set<DataNeed> = [.steps]
    public static let permission = PermissionRequirement(
        need: .steps,
        title: "Steps",
        explanation: "Clay shows your step count on widgets you design.",
        symbolName: "figure.walk.motion")

    public nonisolated static func timelineNeed(config: StepsConfig) -> TimelineNeed {
        .every(30 * 60)
    }

    @MainActor
    public static func render(
        config: StepsConfig,
        style: ResolvedBlockStyle,
        snapshot: BlockDataSnapshot,
        context: BlockRenderContext
    ) -> AnyView {
        AnyView(StepsBlockView(
            config: config, style: style,
            steps: snapshot.steps, family: context.family))
    }

    @MainActor
    public static func configEditor(config: Binding<StepsConfig>) -> AnyView {
        AnyView(StepsConfigEditor(config: config))
    }
}

private struct StepsBlockView: View {
    let config: StepsConfig
    let style: ResolvedBlockStyle
    let steps: StepsSnapshot?
    let family: WidgetFamilyKey

    private var count: Int { steps?.count ?? 0 }
    private var progress: Double {
        guard config.goal > 0 else { return 0 }
        return min(1, Double(count) / Double(config.goal))
    }

    var body: some View {
        if config.isRing && family != .accessoryInline {
            ZStack {
                Circle()
                    .stroke(style.secondaryColor.opacity(0.35), lineWidth: 5)
                Circle()
                    .trim(from: 0, to: max(0.02, progress))
                    .stroke(
                        style.tintColor ?? style.primaryColor,
                        style: StrokeStyle(lineWidth: 5, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                VStack(spacing: 0) {
                    Image(systemName: "figure.walk")
                        .font(.system(size: 9, weight: .bold))
                        .foregroundStyle(style.tintColor ?? style.secondaryColor)
                    Text(count, format: .number.notation(.compactName))
                        .font(style.font(size: 14))
                        .foregroundStyle(style.primaryColor)
                }
            }
            .aspectRatio(1, contentMode: .fit)
            .padding(3)
        } else {
            HStack(spacing: 4) {
                Image(systemName: "figure.walk")
                    .foregroundStyle(style.tintColor ?? style.primaryColor)
                Text(count, format: .number)
                    .font(style.font(size: 15))
                    .foregroundStyle(style.primaryColor)
            }
        }
    }
}

private struct StepsConfigEditor: View {
    @Binding var config: StepsConfig

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            OptionChips(
                options: [("Ring", "ring"), ("Count", "count")],
                selection: $config.style)
                .padding(.vertical, UX.rowVPadding)
            Divider()
            SliderRow(
                "Goal",
                value: Binding(
                    get: { Double(config.goal) },
                    set: { config.goal = Int($0) }),
                in: 2000...20_000,
                step: 500
            ) { value in
                Int(value).formatted(.number.notation(.compactName))
            }
        }
    }
}
