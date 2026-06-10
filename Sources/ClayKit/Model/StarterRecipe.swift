/**
 The recipe seeded on first launch — also the widget gallery's placeholder
 content, so a freshly-installed Clay never shows a blank widget anywhere.
 */
import Foundation

extension WidgetRecipe {
    public static func starter() -> WidgetRecipe {
        WidgetRecipe(
            name: "First Light",
            blocks: [
                BlockInstance(kind: .clock, weight: 2),
                BlockInstance(kind: .date, weight: 1),
            ],
            theme: WidgetTheme(
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
                corner: CornerSpec(radius: 22, continuous: true)))
    }
}
