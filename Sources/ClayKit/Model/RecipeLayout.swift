/**
 `RecipeLayout`: how a recipe's blocks arrange per widget family. A weighted
 axis stack — one drag-ordered block list maps 1:1 onto the editor, composes
 to any family by changing axis/visible set, and avoids slot-grid management UI.
 */
import Foundation

public enum LayoutAxis: String, Codable, Sendable {
    case vertical
    case horizontal
}

public enum LayoutAlignment: String, Codable, Sendable {
    case leading
    case center
    case trailing
}

public struct FamilyArrangement: Codable, Hashable, Sendable {
    public var axis: LayoutAxis
    public var spacing: Double
    public var padding: Double
    public var alignment: LayoutAlignment
    /// Which blocks this family shows, in order. `nil` = all blocks in recipe
    /// order. Accessory families typically pick a single block.
    public var visibleBlockIDs: [UUID]?

    public init(
        axis: LayoutAxis = .vertical,
        spacing: Double = 8,
        padding: Double = 12,
        alignment: LayoutAlignment = .center,
        visibleBlockIDs: [UUID]? = nil
    ) {
        self.axis = axis
        self.spacing = spacing
        self.padding = padding
        self.alignment = alignment
        self.visibleBlockIDs = visibleBlockIDs
    }

    enum CodingKeys: String, CodingKey {
        case axis, spacing, padding, alignment, visibleBlockIDs
    }

    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        axis = (try? c.decodeIfPresent(LayoutAxis.self, forKey: .axis)) ?? .vertical
        spacing = try c.decodeIfPresent(Double.self, forKey: .spacing) ?? 8
        padding = try c.decodeIfPresent(Double.self, forKey: .padding) ?? 12
        alignment = (try? c.decodeIfPresent(LayoutAlignment.self, forKey: .alignment)) ?? .center
        visibleBlockIDs = try c.decodeIfPresent([UUID].self, forKey: .visibleBlockIDs)
    }
}

public struct RecipeLayout: Codable, Hashable, Sendable {
    /// Missing families fall back to `FamilyArrangement()` defaults (or a
    /// horizontal arrangement for inline accessories).
    public var arrangements: [WidgetFamilyKey: FamilyArrangement]

    public init(arrangements: [WidgetFamilyKey: FamilyArrangement] = [:]) {
        self.arrangements = arrangements
    }

    public func arrangement(for family: WidgetFamilyKey) -> FamilyArrangement {
        if let explicit = arrangements[family] { return explicit }
        switch family {
        case .medium, .accessoryInline:
            return FamilyArrangement(axis: .horizontal)
        default:
            return FamilyArrangement()
        }
    }

    // Encode the dictionary keyed by raw string so the JSON stays a plain
    // object ({"small": …}) instead of Codable's array-of-pairs form for
    // non-String dictionary keys — and unknown future family keys are skipped,
    // not fatal.
    public init(from decoder: Decoder) throws {
        let c = try decoder.singleValueContainer()
        let raw = (try? c.decode([String: FamilyArrangement].self)) ?? [:]
        var result: [WidgetFamilyKey: FamilyArrangement] = [:]
        for (key, value) in raw {
            if let family = WidgetFamilyKey(rawValue: key) {
                result[family] = value
            }
        }
        arrangements = result
    }

    public func encode(to encoder: Encoder) throws {
        var c = encoder.singleValueContainer()
        let raw = Dictionary(uniqueKeysWithValues: arrangements.map { ($0.key.rawValue, $0.value) })
        try c.encode(raw)
    }
}
