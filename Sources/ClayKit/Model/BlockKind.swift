/**
 `BlockKind`: the discriminator for block types in a recipe. A string-backed
 struct, NOT an enum — recipes containing kinds this build doesn't know (newer
 versions, future blocks) must decode, render a placeholder, and re-encode
 losslessly. An enum would fail the whole recipe on one unknown case.
 */
import Foundation

public struct BlockKind: RawRepresentable, Codable, Hashable, Sendable {
    public let rawValue: String

    public init(rawValue: String) {
        self.rawValue = rawValue
    }

    public init(from decoder: Decoder) throws {
        rawValue = try decoder.singleValueContainer().decode(String.self)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(rawValue)
    }

    // Launch blocks.
    public static let clock = BlockKind(rawValue: "clock")
    public static let date = BlockKind(rawValue: "date")
    public static let calendar = BlockKind(rawValue: "calendar")
    public static let battery = BlockKind(rawValue: "battery")
    public static let weather = BlockKind(rawValue: "weather")
    public static let photo = BlockKind(rawValue: "photo")
    public static let countdown = BlockKind(rawValue: "countdown")
    public static let quote = BlockKind(rawValue: "quote")
    public static let steps = BlockKind(rawValue: "steps")
}
