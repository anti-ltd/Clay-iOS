/**
 `BlockInstance`: one block in a recipe — a kind discriminator, an opaque
 typed-at-use-site config, an optional style override, and a layout weight.
 The config stays `JSONValue` at rest so unknown kinds/fields survive decode
 and re-encode untouched.
 */
import Foundation

public struct BlockInstance: Codable, Identifiable, Hashable, Sendable {
    public var id: UUID
    public var kind: BlockKind
    public var config: JSONValue
    public var styleOverride: BlockStyleOverride?
    /// Relative share of the layout axis, against sibling weights. Default 1.
    public var weight: Double

    public init(
        id: UUID = UUID(),
        kind: BlockKind,
        config: JSONValue = .object([:]),
        styleOverride: BlockStyleOverride? = nil,
        weight: Double = 1
    ) {
        self.id = id
        self.kind = kind
        self.config = config
        self.styleOverride = styleOverride
        self.weight = weight
    }

    enum CodingKeys: String, CodingKey {
        case id, kind, config, styleOverride, weight
    }

    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decodeIfPresent(UUID.self, forKey: .id) ?? UUID()
        kind = try c.decode(BlockKind.self, forKey: .kind)
        config = try c.decodeIfPresent(JSONValue.self, forKey: .config) ?? .object([:])
        styleOverride = try c.decodeIfPresent(BlockStyleOverride.self, forKey: .styleOverride)
        weight = try c.decodeIfPresent(Double.self, forKey: .weight) ?? 1
    }
}
