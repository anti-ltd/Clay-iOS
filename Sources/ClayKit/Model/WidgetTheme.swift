/**
 `WidgetTheme`: every visual layer of a widget — background treatment, glass
 material, depth, blur, tint, gradient, typography, corner geometry, foreground.
 Themes are user-editable end to end; presets live in `ThemePresets`.

 Forward compatibility: every field decodes with a default so recipes written
 by newer versions (with theme fields this build doesn't know) still open.
 */
import Foundation

public struct WidgetTheme: Codable, Hashable, Sendable, Identifiable {
    /// "preset.<name>" for shipped presets, "custom.<uuid>" once edited.
    public var id: String
    public var name: String
    public var background: BackgroundSpec
    /// 0…1 — drives shadow radius/opacity for the floating-card look.
    public var depth: Double
    /// 0…1 — overlay blur applied to background imagery layers.
    public var blur: Double
    /// Accent wash over the material, top-leading (the iUX glass idiom).
    public var tint: RGBA?
    public var typography: TypographySpec
    public var corner: CornerSpec
    public var foreground: ForegroundSpec

    public init(
        id: String,
        name: String,
        background: BackgroundSpec = .material(.ultraThin),
        depth: Double = 0.5,
        blur: Double = 0,
        tint: RGBA? = nil,
        typography: TypographySpec = TypographySpec(),
        corner: CornerSpec = CornerSpec(),
        foreground: ForegroundSpec = ForegroundSpec()
    ) {
        self.id = id
        self.name = name
        self.background = background
        self.depth = depth
        self.blur = blur
        self.tint = tint
        self.typography = typography
        self.corner = corner
        self.foreground = foreground
    }

    enum CodingKeys: String, CodingKey {
        case id, name, background, depth, blur, tint, typography, corner, foreground
    }

    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decodeIfPresent(String.self, forKey: .id) ?? "custom.\(UUID().uuidString)"
        name = try c.decodeIfPresent(String.self, forKey: .name) ?? "Theme"
        background = try c.decodeIfPresent(BackgroundSpec.self, forKey: .background) ?? .material(.ultraThin)
        depth = try c.decodeIfPresent(Double.self, forKey: .depth) ?? 0.5
        blur = try c.decodeIfPresent(Double.self, forKey: .blur) ?? 0
        tint = try c.decodeIfPresent(RGBA.self, forKey: .tint)
        typography = try c.decodeIfPresent(TypographySpec.self, forKey: .typography) ?? TypographySpec()
        corner = try c.decodeIfPresent(CornerSpec.self, forKey: .corner) ?? CornerSpec()
        foreground = try c.decodeIfPresent(ForegroundSpec.self, forKey: .foreground) ?? ForegroundSpec()
    }
}

// MARK: - Background

/// The widget's background treatment. String-discriminated (not an enum with
/// associated values in the wire format) so unknown future kinds degrade to
/// `.material(.ultraThin)` instead of failing the decode.
public enum BackgroundSpec: Codable, Hashable, Sendable {
    case material(MaterialKind)
    case tint(RGBA)
    case gradient(GradientSpec)
    case clear

    enum CodingKeys: String, CodingKey { case kind, material, tint, gradient }

    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        let kind = try c.decodeIfPresent(String.self, forKey: .kind) ?? "material"
        switch kind {
        case "tint":
            self = .tint(try c.decodeIfPresent(RGBA.self, forKey: .tint) ?? RGBA(hex: 0x000000))
        case "gradient":
            self = .gradient(try c.decodeIfPresent(GradientSpec.self, forKey: .gradient) ?? GradientSpec())
        case "clear":
            self = .clear
        default:
            self = .material(try c.decodeIfPresent(MaterialKind.self, forKey: .material) ?? .ultraThin)
        }
    }

    public func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        switch self {
        case .material(let material):
            try c.encode("material", forKey: .kind)
            try c.encode(material, forKey: .material)
        case .tint(let tint):
            try c.encode("tint", forKey: .kind)
            try c.encode(tint, forKey: .tint)
        case .gradient(let gradient):
            try c.encode("gradient", forKey: .kind)
            try c.encode(gradient, forKey: .gradient)
        case .clear:
            try c.encode("clear", forKey: .kind)
        }
    }
}

/// Glass material weight. Unknown raw values decode as `.ultraThin`.
public struct MaterialKind: RawRepresentable, Codable, Hashable, Sendable {
    public let rawValue: String
    public init(rawValue: String) { self.rawValue = rawValue }

    public static let ultraThin = MaterialKind(rawValue: "ultraThin")
    public static let thin = MaterialKind(rawValue: "thin")
    public static let regular = MaterialKind(rawValue: "regular")
    public static let thick = MaterialKind(rawValue: "thick")
}

public struct GradientSpec: Codable, Hashable, Sendable {
    public struct Stop: Codable, Hashable, Sendable {
        public var color: RGBA
        public var location: Double

        public init(color: RGBA, location: Double) {
            self.color = color
            self.location = location
        }
    }

    public var stops: [Stop]
    /// 0° = bottom→top, 90° = leading→trailing; matches design-tool convention.
    public var angleDegrees: Double

    public init(
        stops: [Stop] = [
            Stop(color: RGBA(hex: 0x14122E), location: 0),
            Stop(color: RGBA(hex: 0x3B336E), location: 1),
        ],
        angleDegrees: Double = 45
    ) {
        self.stops = stops
        self.angleDegrees = angleDegrees
    }
}

// MARK: - Typography

public struct TypographySpec: Codable, Hashable, Sendable {
    /// Multiplier applied to every block's base type size. 1 = the design size.
    public var scale: Double
    /// Maps to `Font.Design`: "default" / "rounded" / "serif" / "monospaced".
    /// String so future designs degrade gracefully.
    public var design: String
    /// Maps to `Font.Weight`: "light" / "regular" / "medium" / "semibold" / "bold".
    public var weight: String

    public init(scale: Double = 1, design: String = "default", weight: String = "regular") {
        self.scale = scale
        self.design = design
        self.weight = weight
    }
}

// MARK: - Corner geometry

public struct CornerSpec: Codable, Hashable, Sendable {
    /// Block corner radius in points at small-family scale.
    public var radius: Double
    /// Continuous (squircle) vs circular corners.
    public var continuous: Bool

    public init(radius: Double = 16, continuous: Bool = true) {
        self.radius = radius
        self.continuous = continuous
    }
}

// MARK: - Foreground

public struct ForegroundSpec: Codable, Hashable, Sendable {
    /// `nil` = auto (white over dark treatments, primary over materials).
    public var primary: RGBA?
    public var secondary: RGBA?

    public init(primary: RGBA? = nil, secondary: RGBA? = nil) {
        self.primary = primary
        self.secondary = secondary
    }
}
