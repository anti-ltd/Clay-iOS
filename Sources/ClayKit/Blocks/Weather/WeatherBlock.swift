/**
 Weather block — WeatherKit current conditions, cached aggressively (the
 provider's App Group cache means most widget reloads are disk reads, not
 network).
 */
import SwiftUI
import iUXiOS

public struct WeatherConfig: Codable, Hashable, Sendable {
    public var showsHiLo: Bool
    public var showsCondition: Bool
    public var unit: String       // "auto" | "celsius" | "fahrenheit"

    public init(showsHiLo: Bool = true, showsCondition: Bool = true, unit: String = "auto") {
        self.showsHiLo = showsHiLo
        self.showsCondition = showsCondition
        self.unit = unit
    }
}

public enum WeatherBlock: BlockModule {
    public static let kind = BlockKind.weather
    public static let displayName = "Weather"
    public static let systemImage = "cloud.sun"
    public static let defaultConfig = WeatherConfig()
    public static let dataNeeds: Set<DataNeed> = [.weather]
    public static let permission = PermissionRequirement(
        need: .weather,
        title: "Weather",
        explanation: "Clay uses your location to show local weather on widgets you design.",
        symbolName: "location")

    public nonisolated static func timelineNeed(config: WeatherConfig) -> TimelineNeed {
        .every(30 * 60)
    }

    @MainActor
    public static func render(
        config: WeatherConfig,
        style: ResolvedBlockStyle,
        snapshot: BlockDataSnapshot,
        context: BlockRenderContext
    ) -> AnyView {
        AnyView(WeatherBlockView(
            config: config, style: style, weather: snapshot.weather, family: context.family))
    }

    @MainActor
    public static func configEditor(config: Binding<WeatherConfig>) -> AnyView {
        AnyView(WeatherConfigEditor(config: config))
    }
}

private struct WeatherBlockView: View {
    let config: WeatherConfig
    let style: ResolvedBlockStyle
    let weather: WeatherSnapshot?
    let family: WidgetFamilyKey

    private func formatted(_ celsius: Double) -> String {
        let measurement = Measurement(value: celsius, unit: UnitTemperature.celsius)
        let formatter = MeasurementFormatter()
        formatter.numberFormatter.maximumFractionDigits = 0
        formatter.unitStyle = .short
        switch config.unit {
        case "celsius": formatter.unitOptions = .providedUnit
        case "fahrenheit":
            formatter.unitOptions = .providedUnit
            return formatter.string(from: measurement.converted(to: .fahrenheit))
        default: formatter.unitOptions = .temperatureWithoutUnit
        }
        return formatter.string(from: measurement)
    }

    var body: some View {
        if let weather {
            VStack(spacing: 2) {
                HStack(spacing: 5) {
                    Image(systemName: weather.symbolName)
                        .font(.system(size: family.isAccessory ? 14 : 20))
                        .foregroundStyle(style.tintColor ?? style.primaryColor)
                    Text(formatted(weather.temperature))
                        .font(style.font(size: family.isAccessory ? 17 : 26))
                        .foregroundStyle(style.primaryColor)
                }
                if config.showsCondition && !family.isAccessory {
                    Text(weather.conditionDescription)
                        .font(style.font(size: 11))
                        .foregroundStyle(style.secondaryColor)
                }
                if config.showsHiLo && !family.isAccessory {
                    Text("H \(formatted(weather.highTemperature))  L \(formatted(weather.lowTemperature))")
                        .font(style.font(size: 10))
                        .foregroundStyle(style.secondaryColor)
                }
            }
            .lineLimit(1)
        } else {
            // Granted but no data yet (first fetch pending / offline).
            VStack(spacing: 3) {
                Image(systemName: "cloud")
                    .font(.system(size: 16, weight: .light))
                Text("Updating…")
                    .font(style.font(size: 11))
            }
            .foregroundStyle(style.secondaryColor)
        }
    }
}

private struct WeatherConfigEditor: View {
    @Binding var config: WeatherConfig

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            OptionChips(
                options: [("Auto", "auto"), ("°C", "celsius"), ("°F", "fahrenheit")],
                selection: $config.unit)
                .padding(.vertical, UX.rowVPadding)
            Divider()
            ToggleRow("Condition", isOn: $config.showsCondition)
            Divider()
            ToggleRow("High / Low", isOn: $config.showsHiLo)
        }
    }
}
