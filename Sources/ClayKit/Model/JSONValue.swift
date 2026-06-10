/**
 `JSONValue`: a self-describing, lossless any-JSON value. The carrier for block
 configs inside `BlockInstance` — recipes round-trip configs they don't
 understand (newer app versions, unknown block kinds) byte-for-byte in meaning,
 so saving a recipe never destroys data authored by a future version.
 */
import Foundation

public enum JSONValue: Codable, Hashable, Sendable {
    case string(String)
    case number(Double)
    case bool(Bool)
    case null
    case array([JSONValue])
    case object([String: JSONValue])

    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if container.decodeNil() {
            self = .null
        } else if let value = try? container.decode(Bool.self) {
            self = .bool(value)
        } else if let value = try? container.decode(Double.self) {
            self = .number(value)
        } else if let value = try? container.decode(String.self) {
            self = .string(value)
        } else if let value = try? container.decode([JSONValue].self) {
            self = .array(value)
        } else if let value = try? container.decode([String: JSONValue].self) {
            self = .object(value)
        } else {
            throw DecodingError.dataCorruptedError(
                in: container, debugDescription: "Unrecognized JSON value")
        }
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch self {
        case .string(let value): try container.encode(value)
        case .number(let value): try container.encode(value)
        case .bool(let value): try container.encode(value)
        case .null: try container.encodeNil()
        case .array(let value): try container.encode(value)
        case .object(let value): try container.encode(value)
        }
    }
}

// MARK: - Typed bridging

extension JSONValue {
    /// Wrap any `Encodable` (a block module's typed `Config`) as a `JSONValue`.
    public init<T: Encodable>(encoding value: T) throws {
        let data = try JSONEncoder().encode(value)
        self = try JSONDecoder().decode(JSONValue.self, from: data)
    }

    /// Unwrap into a typed value. Returns `nil` on any mismatch — callers fall
    /// back to the module's `defaultConfig` rather than failing the recipe.
    public func decoded<T: Decodable>(as type: T.Type) -> T? {
        guard let data = try? JSONEncoder().encode(self) else { return nil }
        return try? JSONDecoder().decode(T.self, from: data)
    }

    /// Decode tolerantly by layering this value over `defaults`: missing keys
    /// fill in from the default's encoding, unknown keys are ignored by the
    /// decoder. This is what makes PARTIAL configs valid — a recipe written
    /// before a config gained a field (or hand-authored with two keys) decodes
    /// to "defaults + what it says" instead of resetting wholesale.
    public func decoded<T: Codable>(as type: T.Type, filling defaults: T) -> T {
        guard let defaultValue = try? JSONValue(encoding: defaults) else {
            return decoded(as: T.self) ?? defaults
        }
        return defaultValue.merging(self).decoded(as: T.self) ?? defaults
    }

    /// Recursive object merge; `other` wins, non-objects replace wholesale.
    public func merging(_ other: JSONValue) -> JSONValue {
        guard case .object(let base) = self, case .object(let overlay) = other else {
            return other
        }
        var merged = base
        for (key, value) in overlay {
            merged[key] = base[key].map { $0.merging(value) } ?? value
        }
        return .object(merged)
    }
}
