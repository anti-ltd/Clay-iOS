/**
 `BlockStyleOverride`: per-block deviations from the recipe's theme — every
 field optional, merged over the theme by `ResolvedBlockStyle`. "Deep
 customization is the brand": any block can opt out of any theme decision.
 */
import Foundation

public struct BlockStyleOverride: Codable, Hashable, Sendable {
    public var background: BackgroundSpec?
    public var depth: Double?
    public var blur: Double?
    public var tint: RGBA?
    public var typography: TypographySpec?
    public var corner: CornerSpec?
    public var foreground: ForegroundSpec?

    public init(
        background: BackgroundSpec? = nil,
        depth: Double? = nil,
        blur: Double? = nil,
        tint: RGBA? = nil,
        typography: TypographySpec? = nil,
        corner: CornerSpec? = nil,
        foreground: ForegroundSpec? = nil
    ) {
        self.background = background
        self.depth = depth
        self.blur = blur
        self.tint = tint
        self.typography = typography
        self.corner = corner
        self.foreground = foreground
    }

    /// True when nothing is overridden — the editor uses this to show/hide
    /// the "reset to theme" affordance.
    public var isEmpty: Bool {
        background == nil && depth == nil && blur == nil && tint == nil
            && typography == nil && corner == nil && foreground == nil
    }
}

/// The flattened style a renderer actually consumes: theme values with the
/// block's overrides merged on top. Renderers never see the theme or the
/// override separately.
public struct ResolvedBlockStyle: Hashable, Sendable {
    public var background: BackgroundSpec
    public var depth: Double
    public var blur: Double
    public var tint: RGBA?
    public var typography: TypographySpec
    public var corner: CornerSpec
    public var foreground: ForegroundSpec

    public init(theme: WidgetTheme, override: BlockStyleOverride? = nil) {
        background = override?.background ?? theme.background
        depth = override?.depth ?? theme.depth
        blur = override?.blur ?? theme.blur
        tint = override?.tint ?? theme.tint
        typography = override?.typography ?? theme.typography
        corner = override?.corner ?? theme.corner
        foreground = override?.foreground ?? theme.foreground
    }
}
