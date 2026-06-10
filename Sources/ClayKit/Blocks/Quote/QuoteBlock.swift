/**
 Quote block — built-in packs (bundled JSON, rotated daily and deterministic
 per entry date) or the user's own text. The provider picks the quote into the
 snapshot; the renderer just displays its selection.
 */
import SwiftUI
import iUXiOS

public struct QuoteConfig: Codable, Hashable, Sendable {
    /// "custom" renders `customText`; otherwise a bundled pack id.
    public var packID: String
    public var customText: String
    public var customAttribution: String
    public var showsAttribution: Bool

    public init(
        packID: String = "classic",
        customText: String = "",
        customAttribution: String = "",
        showsAttribution: Bool = true
    ) {
        self.packID = packID
        self.customText = customText
        self.customAttribution = customAttribution
        self.showsAttribution = showsAttribution
    }

    public var isCustom: Bool { packID == "custom" }
}

public enum QuoteBlock: BlockModule {
    public static let kind = BlockKind.quote
    public static let displayName = "Quote"
    public static let systemImage = "quote.opening"
    public static let defaultConfig = QuoteConfig()
    public static let dataNeeds: Set<DataNeed> = [.time]
    public static let supportedFamilies: Set<WidgetFamilyKey> =
        [.small, .medium, .large, .accessoryRectangular, .accessoryInline]

    public nonisolated static func timelineNeed(config: QuoteConfig) -> TimelineNeed {
        config.isCustom ? .staticEntry : .every(86_400)
    }

    @MainActor
    public static func render(
        config: QuoteConfig,
        style: ResolvedBlockStyle,
        snapshot: BlockDataSnapshot,
        context: BlockRenderContext
    ) -> AnyView {
        let quote = snapshot.quoteSelection[context.instanceID]
            ?? QuoteSnapshot(
                text: config.isCustom && !config.customText.isEmpty
                    ? config.customText : "Dress your phone.",
                attribution: config.isCustom ? config.customAttribution : "Clay")
        return AnyView(QuoteBlockView(
            config: config, style: style, quote: quote, family: context.family))
    }

    @MainActor
    public static func configEditor(config: Binding<QuoteConfig>) -> AnyView {
        AnyView(QuoteConfigEditor(config: config))
    }
}

private struct QuoteBlockView: View {
    let config: QuoteConfig
    let style: ResolvedBlockStyle
    let quote: QuoteSnapshot
    let family: WidgetFamilyKey

    var body: some View {
        VStack(spacing: 4) {
            Text(quote.text)
                .font(style.font(size: family.isAccessory ? 13 : 16))
                .foregroundStyle(style.primaryColor)
                .multilineTextAlignment(.center)
                .minimumScaleFactor(0.6)
            if config.showsAttribution,
               let attribution = quote.attribution, !attribution.isEmpty,
               !family.isAccessory {
                Text("— \(attribution)")
                    .font(style.font(size: 11))
                    .foregroundStyle(style.secondaryColor)
            }
        }
    }
}

private struct QuoteConfigEditor: View {
    @Binding var config: QuoteConfig

    private static let packOptions: [(label: String, tag: String)] =
        QuotePacks.allPacks.map { ($0.name, $0.id) } + [("My Own", "custom")]

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            OptionChips(options: Self.packOptions, selection: $config.packID)
                .padding(.vertical, UX.rowVPadding)
            if config.isCustom {
                Divider()
                TextFieldRow("Quote", prompt: "Your words", text: $config.customText, axis: .vertical)
                Divider()
                TextFieldRow("Credit", prompt: "Who said it (optional)", text: $config.customAttribution)
            }
            Divider()
            ToggleRow("Attribution", isOn: $config.showsAttribution)
        }
    }
}
