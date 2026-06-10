/**
 Clock block — analog (drawn hands, per-minute timeline entries) and digital
 (`Text(_, style: .time)`, which WidgetKit keeps live for free).
 */
import SwiftUI
import iUXiOS

public struct ClockConfig: Codable, Hashable, Sendable {
    public var style: String          // "digital" | "analog"
    public var showsSeconds: Bool     // analog in-app preview only; widgets get minute hands
    public var showsTicks: Bool       // analog face tick marks

    public init(style: String = "digital", showsSeconds: Bool = false, showsTicks: Bool = true) {
        self.style = style
        self.showsSeconds = showsSeconds
        self.showsTicks = showsTicks
    }

    public var isAnalog: Bool { style == "analog" }
}

public enum ClockBlock: BlockModule {
    public static let kind = BlockKind.clock
    public static let displayName = "Clock"
    public static let systemImage = "clock"
    public static let defaultConfig = ClockConfig()
    public static let dataNeeds: Set<DataNeed> = [.time]

    public nonisolated static func timelineNeed(config: ClockConfig) -> TimelineNeed {
        config.isAnalog ? .perMinute : .selfUpdatingText
    }

    @MainActor
    public static func render(
        config: ClockConfig,
        style: ResolvedBlockStyle,
        snapshot: BlockDataSnapshot,
        context: BlockRenderContext
    ) -> AnyView {
        if config.isAnalog, context.family != .accessoryInline {
            AnyView(AnalogClockFace(config: config, style: style, date: snapshot.date))
        } else {
            AnyView(DigitalClockText(style: style, date: snapshot.date, family: context.family))
        }
    }

    @MainActor
    public static func configEditor(config: Binding<ClockConfig>) -> AnyView {
        AnyView(ClockConfigEditor(config: config))
    }
}

// MARK: - Renderers

private struct DigitalClockText: View {
    let style: ResolvedBlockStyle
    let date: Date
    let family: WidgetFamilyKey

    var body: some View {
        // `Text(_, style: .time)` stays current without timeline entries —
        // WidgetKit live-updates date-styled text.
        Text(date, style: .time)
            .font(style.font(size: family.isAccessory ? 24 : 40))
            .monospacedDigit()
            .foregroundStyle(style.primaryColor)
            .minimumScaleFactor(0.5)
            .lineLimit(1)
    }
}

private struct AnalogClockFace: View {
    let config: ClockConfig
    let style: ResolvedBlockStyle
    let date: Date

    var body: some View {
        Canvas { context, size in
            let center = CGPoint(x: size.width / 2, y: size.height / 2)
            let radius = min(size.width, size.height) / 2 - 2

            let calendar = Calendar.current
            let hour = Double(calendar.component(.hour, from: date) % 12)
            let minute = Double(calendar.component(.minute, from: date))
            let second = Double(calendar.component(.second, from: date))

            let primary = style.primaryColor
            let secondary = style.secondaryColor

            // Face ring.
            let ring = Path(ellipseIn: CGRect(
                x: center.x - radius, y: center.y - radius,
                width: radius * 2, height: radius * 2))
            context.stroke(ring, with: .color(secondary.opacity(0.5)), lineWidth: 1.5)

            // Tick marks at the hours.
            if config.showsTicks {
                for tick in 0..<12 {
                    let angle = Double(tick) / 12 * 2 * .pi - .pi / 2
                    let isQuarter = tick % 3 == 0
                    let outer = point(at: angle, radius: radius - 3, center: center)
                    let inner = point(at: angle, radius: radius - (isQuarter ? 10 : 7), center: center)
                    var path = Path()
                    path.move(to: inner)
                    path.addLine(to: outer)
                    context.stroke(
                        path,
                        with: .color(isQuarter ? primary : secondary),
                        style: StrokeStyle(lineWidth: isQuarter ? 2 : 1, lineCap: .round))
                }
            }

            // Hands.
            let hourAngle = (hour + minute / 60) / 12 * 2 * .pi - .pi / 2
            let minuteAngle = minute / 60 * 2 * .pi - .pi / 2
            drawHand(context: &context, center: center, angle: hourAngle,
                     length: radius * 0.5, width: 3.5, color: primary)
            drawHand(context: &context, center: center, angle: minuteAngle,
                     length: radius * 0.74, width: 2.5, color: primary)

            if config.showsSeconds {
                let secondAngle = second / 60 * 2 * .pi - .pi / 2
                drawHand(context: &context, center: center, angle: secondAngle,
                         length: radius * 0.8, width: 1,
                         color: style.tintColor ?? secondary)
            }

            // Hub.
            let hub = Path(ellipseIn: CGRect(x: center.x - 3, y: center.y - 3, width: 6, height: 6))
            context.fill(hub, with: .color(primary))
        }
        .aspectRatio(1, contentMode: .fit)
    }

    private func point(at angle: Double, radius: Double, center: CGPoint) -> CGPoint {
        CGPoint(x: center.x + cos(angle) * radius, y: center.y + sin(angle) * radius)
    }

    private func drawHand(
        context: inout GraphicsContext, center: CGPoint, angle: Double,
        length: Double, width: Double, color: Color
    ) {
        var path = Path()
        path.move(to: center)
        path.addLine(to: point(at: angle, radius: length, center: center))
        context.stroke(path, with: .color(color), style: StrokeStyle(lineWidth: width, lineCap: .round))
    }
}

// MARK: - Config editor

/// Embedded inside a `CardSection` by BlockInspectorView; rows follow the iUX
/// settings idiom.
private struct ClockConfigEditor: View {
    @Binding var config: ClockConfig

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            OptionChips(
                options: [("Digital", "digital"), ("Analog", "analog")],
                selection: $config.style)
                .padding(.vertical, UX.rowVPadding)
            if config.isAnalog {
                Divider()
                ToggleRow("Tick Marks", isOn: $config.showsTicks)
                Divider()
                ToggleRow(
                    "Second Hand",
                    subtitle: "Shown in the app preview; widgets update by the minute.",
                    isOn: $config.showsSeconds)
            }
        }
    }
}
