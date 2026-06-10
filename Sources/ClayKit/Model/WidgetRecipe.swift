/**
 `WidgetRecipe`: the unit of the product — a layout recipe + an ordered set of
 blocks + a style theme. Serialized to the App Group store; the widget
 extension renders saved recipes from the same file the app writes.

 Forward-compat contract (enforced by tests):
 - every field decodes with a default, so newer-version recipes still open
 - `schemaVersion` greater than `currentSchemaVersion` decodes best-effort
 - unknown block kinds survive decode and re-encode losslessly
 */
import Foundation

public struct WidgetRecipe: Codable, Identifiable, Hashable, Sendable {
    public static let currentSchemaVersion = 1

    public var schemaVersion: Int
    public var id: UUID
    public var name: String
    public var createdAt: Date
    public var modifiedAt: Date
    /// Ordered = render order = the editor's drag-ordered list.
    public var blocks: [BlockInstance]
    public var theme: WidgetTheme
    public var layout: RecipeLayout

    public init(
        id: UUID = UUID(),
        name: String,
        createdAt: Date = .now,
        modifiedAt: Date = .now,
        blocks: [BlockInstance] = [],
        theme: WidgetTheme,
        layout: RecipeLayout = RecipeLayout()
    ) {
        self.schemaVersion = Self.currentSchemaVersion
        self.id = id
        self.name = name
        self.createdAt = createdAt
        self.modifiedAt = modifiedAt
        self.blocks = blocks
        self.theme = theme
        self.layout = layout
    }

    enum CodingKeys: String, CodingKey {
        case schemaVersion, id, name, createdAt, modifiedAt, blocks, theme, layout
    }

    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        schemaVersion = try c.decodeIfPresent(Int.self, forKey: .schemaVersion) ?? 1
        id = try c.decodeIfPresent(UUID.self, forKey: .id) ?? UUID()
        name = try c.decodeIfPresent(String.self, forKey: .name) ?? "Widget"
        createdAt = try c.decodeIfPresent(Date.self, forKey: .createdAt) ?? .now
        modifiedAt = try c.decodeIfPresent(Date.self, forKey: .modifiedAt) ?? .now
        blocks = try c.decodeIfPresent([BlockInstance].self, forKey: .blocks) ?? []
        theme = try c.decodeIfPresent(WidgetTheme.self, forKey: .theme)
            ?? WidgetTheme(id: "custom.\(UUID().uuidString)", name: "Theme")
        layout = try c.decodeIfPresent(RecipeLayout.self, forKey: .layout) ?? RecipeLayout()
    }
}
