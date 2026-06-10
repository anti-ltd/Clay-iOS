/**
 The shipped themes — code, not JSON: they're design artifacts that should be
 reviewed in diffs (the Clink theme precedent). Selecting a preset copies its
 values into the recipe; edits then make it the user's own.
 */
import Foundation

public enum ThemePresets {
    public static let all: [WidgetTheme] = [
        midnight, frost, ember, mono, lagoon, orchid, sandstone, pine, neon, paper,
    ]

    public static let midnight = WidgetTheme(
        id: "preset.midnight",
        name: "Midnight",
        background: .gradient(GradientSpec(
            stops: [
                .init(color: RGBA(hex: 0x14122E), location: 0),
                .init(color: RGBA(hex: 0x3B336E), location: 1),
            ],
            angleDegrees: 40)),
        depth: 0.6,
        tint: RGBA(hex: 0x8B7CF8),
        typography: TypographySpec(scale: 1, design: "rounded", weight: "medium"),
        corner: CornerSpec(radius: 22, continuous: true))

    public static let frost = WidgetTheme(
        id: "preset.frost",
        name: "Frost",
        background: .material(.ultraThin),
        depth: 0.35,
        tint: RGBA(hex: 0x9BD1FF),
        typography: TypographySpec(scale: 1, design: "default", weight: "regular"),
        corner: CornerSpec(radius: 20, continuous: true))

    public static let ember = WidgetTheme(
        id: "preset.ember",
        name: "Ember",
        background: .gradient(GradientSpec(
            stops: [
                .init(color: RGBA(hex: 0x2A0E08), location: 0),
                .init(color: RGBA(hex: 0x7A2D12), location: 1),
            ],
            angleDegrees: 30)),
        depth: 0.7,
        tint: RGBA(hex: 0xFF9F6B),
        typography: TypographySpec(scale: 1.05, design: "serif", weight: "medium"),
        corner: CornerSpec(radius: 18, continuous: true))

    public static let mono = WidgetTheme(
        id: "preset.mono",
        name: "Mono",
        background: .tint(RGBA(hex: 0x0A0A0C)),
        depth: 0.5,
        tint: nil,
        typography: TypographySpec(scale: 1, design: "monospaced", weight: "regular"),
        corner: CornerSpec(radius: 8, continuous: false),
        foreground: ForegroundSpec(
            primary: RGBA(hex: 0xEDEDED), secondary: RGBA(hex: 0x8E8E93)))

    public static let lagoon = WidgetTheme(
        id: "preset.lagoon",
        name: "Lagoon",
        background: .gradient(GradientSpec(
            stops: [
                .init(color: RGBA(hex: 0x05222B), location: 0),
                .init(color: RGBA(hex: 0x0F5E63), location: 1),
            ],
            angleDegrees: 60)),
        depth: 0.55,
        tint: RGBA(hex: 0x5FE3C9),
        typography: TypographySpec(scale: 1, design: "rounded", weight: "semibold"),
        corner: CornerSpec(radius: 26, continuous: true))

    public static let orchid = WidgetTheme(
        id: "preset.orchid",
        name: "Orchid",
        background: .gradient(GradientSpec(
            stops: [
                .init(color: RGBA(hex: 0x2B0F2E), location: 0),
                .init(color: RGBA(hex: 0x7A2E6E), location: 1),
            ],
            angleDegrees: 135)),
        depth: 0.65,
        tint: RGBA(hex: 0xF38FD8),
        typography: TypographySpec(scale: 1.1, design: "default", weight: "light"),
        corner: CornerSpec(radius: 24, continuous: true))

    public static let sandstone = WidgetTheme(
        id: "preset.sandstone",
        name: "Sandstone",
        background: .tint(RGBA(hex: 0x2C2418)),
        depth: 0.4,
        tint: RGBA(hex: 0xE3C79B),
        typography: TypographySpec(scale: 1, design: "serif", weight: "regular"),
        corner: CornerSpec(radius: 16, continuous: true),
        foreground: ForegroundSpec(
            primary: RGBA(hex: 0xF4EBDD), secondary: RGBA(hex: 0xB7A98E)))

    public static let pine = WidgetTheme(
        id: "preset.pine",
        name: "Pine",
        background: .gradient(GradientSpec(
            stops: [
                .init(color: RGBA(hex: 0x0B1E12), location: 0),
                .init(color: RGBA(hex: 0x1E4D2B), location: 1),
            ],
            angleDegrees: 75)),
        depth: 0.5,
        tint: RGBA(hex: 0x8FD8A0),
        typography: TypographySpec(scale: 1, design: "rounded", weight: "medium"),
        corner: CornerSpec(radius: 20, continuous: true))

    public static let neon = WidgetTheme(
        id: "preset.neon",
        name: "Neon",
        background: .tint(RGBA(hex: 0x060611)),
        depth: 0.8,
        tint: RGBA(hex: 0x46F2E0),
        typography: TypographySpec(scale: 1.05, design: "monospaced", weight: "semibold"),
        corner: CornerSpec(radius: 14, continuous: true),
        foreground: ForegroundSpec(
            primary: RGBA(hex: 0x46F2E0), secondary: RGBA(hex: 0x2A8F86)))

    public static let paper = WidgetTheme(
        id: "preset.paper",
        name: "Paper",
        background: .tint(RGBA(hex: 0xF3EFE7)),
        depth: 0.25,
        tint: RGBA(hex: 0xB04A2F),
        typography: TypographySpec(scale: 1, design: "serif", weight: "regular"),
        corner: CornerSpec(radius: 18, continuous: true),
        foreground: ForegroundSpec(
            primary: RGBA(hex: 0x2B2622), secondary: RGBA(hex: 0x6E665C)))
}
