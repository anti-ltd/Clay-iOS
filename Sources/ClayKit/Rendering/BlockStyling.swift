/**
 Bridges from the Codable style model to SwiftUI: fonts from `TypographySpec`,
 colors from `ForegroundSpec`. Shared by every block renderer so typography
 and foreground decisions look identical across blocks.
 */
import SwiftUI

extension TypographySpec {
    public var fontDesign: Font.Design {
        switch design {
        case "rounded": .rounded
        case "serif": .serif
        case "monospaced": .monospaced
        default: .default
        }
    }

    public var fontWeight: Font.Weight {
        switch weight {
        case "light": .light
        case "medium": .medium
        case "semibold": .semibold
        case "bold": .bold
        default: .regular
        }
    }
}

extension ResolvedBlockStyle {
    /// The themed font at a block's base size: theme scale × block size,
    /// theme design and weight.
    public func font(size: Double) -> Font {
        .system(size: size * typography.scale, weight: typography.fontWeight, design: fontDesign)
    }

    public var fontDesign: Font.Design { typography.fontDesign }

    /// `.auto` foreground = white: every shipped background treatment is a
    /// dark-glass surface (the brand), and accessory families render vibrant
    /// white anyway. Themes targeting light surfaces set explicit colors.
    public var primaryColor: Color {
        foreground.primary?.color ?? .white
    }

    public var secondaryColor: Color {
        foreground.secondary?.color ?? primaryColor.opacity(0.6)
    }

    public var tintColor: Color? { tint?.color }
}
