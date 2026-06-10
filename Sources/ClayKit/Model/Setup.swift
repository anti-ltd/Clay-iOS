/**
 `Setup`: a full look — multiple widget recipes plus a suggested wallpaper
 pairing. Built-in showcase setups ship as JSON in the app bundle; applying a
 setup copies its recipes into the user's store.
 */
import Foundation

public struct Setup: Codable, Identifiable, Hashable, Sendable {
    public static let currentSchemaVersion = 1

    public var schemaVersion: Int
    public var id: UUID
    public var name: String
    public var blurb: String
    public var recipes: [WidgetRecipe]
    public var wallpaper: WallpaperSuggestion?
    public var isBuiltIn: Bool

    public init(
        id: UUID = UUID(),
        name: String,
        blurb: String = "",
        recipes: [WidgetRecipe] = [],
        wallpaper: WallpaperSuggestion? = nil,
        isBuiltIn: Bool = false
    ) {
        self.schemaVersion = Self.currentSchemaVersion
        self.id = id
        self.name = name
        self.blurb = blurb
        self.recipes = recipes
        self.wallpaper = wallpaper
        self.isBuiltIn = isBuiltIn
    }

    enum CodingKeys: String, CodingKey {
        case schemaVersion, id, name, blurb, recipes, wallpaper, isBuiltIn
    }

    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        schemaVersion = try c.decodeIfPresent(Int.self, forKey: .schemaVersion) ?? 1
        id = try c.decodeIfPresent(UUID.self, forKey: .id) ?? UUID()
        name = try c.decodeIfPresent(String.self, forKey: .name) ?? "Setup"
        blurb = try c.decodeIfPresent(String.self, forKey: .blurb) ?? ""
        recipes = try c.decodeIfPresent([WidgetRecipe].self, forKey: .recipes) ?? []
        wallpaper = try c.decodeIfPresent(WallpaperSuggestion.self, forKey: .wallpaper)
        isBuiltIn = try c.decodeIfPresent(Bool.self, forKey: .isBuiltIn) ?? false
    }
}

public struct WallpaperSuggestion: Codable, Hashable, Sendable {
    /// Asset catalog name for bundled image wallpapers, or nil when the
    /// suggestion is a rendered gradient. The setups screen renders it and
    /// offers save-to-Photos (iOS has no set-wallpaper API).
    public var assetName: String?
    /// Procedural wallpaper: rendered full-screen and saveable to Photos
    /// without shipping image assets.
    public var gradient: GradientSpec?
    public var credit: String?

    public init(assetName: String? = nil, gradient: GradientSpec? = nil, credit: String? = nil) {
        self.assetName = assetName
        self.gradient = gradient
        self.credit = credit
    }
}
