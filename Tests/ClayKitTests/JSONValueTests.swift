import XCTest
@testable import Clay

final class JSONValueTests: XCTestCase {
    func testRoundTripAllCases() throws {
        let value = JSONValue.object([
            "string": .string("hello"),
            "number": .number(42.5),
            "int": .number(7),
            "bool": .bool(true),
            "null": .null,
            "array": .array([.string("a"), .number(1), .bool(false), .null]),
            "nested": .object(["deep": .array([.object(["x": .number(0)])])]),
        ])
        let data = try JSONEncoder().encode(value)
        let decoded = try JSONDecoder().decode(JSONValue.self, from: data)
        XCTAssertEqual(decoded, value)
    }

    func testDecodesArbitraryJSON() throws {
        let json = #"{"a": [1, "two", true, null], "b": {"c": 3.5}}"#
        let decoded = try JSONDecoder().decode(JSONValue.self, from: Data(json.utf8))
        guard case .object(let object) = decoded else { return XCTFail("expected object") }
        XCTAssertEqual(object["a"], .array([.number(1), .string("two"), .bool(true), .null]))
        XCTAssertEqual(object["b"], .object(["c": .number(3.5)]))
    }

    func testBoolIsNotConfusedWithNumber() throws {
        let decoded = try JSONDecoder().decode(JSONValue.self, from: Data("[true, 1]".utf8))
        XCTAssertEqual(decoded, .array([.bool(true), .number(1)]))
    }

    func testTypedBridging() throws {
        struct Config: Codable, Equatable {
            var style: String
            var showsSeconds: Bool
            var size: Double
        }
        let config = Config(style: "analog", showsSeconds: true, size: 1.5)
        let wrapped = try JSONValue(encoding: config)
        XCTAssertEqual(wrapped.decoded(as: Config.self), config)
    }

    func testDecodedReturnsNilOnMismatch() {
        struct Config: Codable { var required: String }
        XCTAssertNil(JSONValue.object(["other": .number(1)]).decoded(as: Config.self))
        XCTAssertNil(JSONValue.string("nope").decoded(as: Config.self))
    }

    func testDecodedFillingToleratesPartialConfigs() {
        struct Config: Codable, Equatable {
            var style = "digital"
            var showsSeconds = false
        }
        // Partial: missing key fills from defaults.
        let partial = JSONValue.object(["style": .string("analog")])
        XCTAssertEqual(
            partial.decoded(as: Config.self, filling: Config()),
            Config(style: "analog", showsSeconds: false))

        // Unknown extra keys are ignored; garbage falls back to defaults wholesale.
        let extra = JSONValue.object(["showsSeconds": .bool(true), "future": .null])
        XCTAssertEqual(
            extra.decoded(as: Config.self, filling: Config()),
            Config(style: "digital", showsSeconds: true))
        XCTAssertEqual(
            JSONValue.string("garbage").decoded(as: Config.self, filling: Config()),
            Config())
    }

    func testMergingIsRecursiveAndOverlayWins() {
        let base = JSONValue.object([
            "a": .number(1),
            "nested": .object(["x": .number(1), "y": .number(2)]),
        ])
        let overlay = JSONValue.object([
            "nested": .object(["y": .number(9)]),
            "b": .bool(true),
        ])
        XCTAssertEqual(base.merging(overlay), .object([
            "a": .number(1),
            "nested": .object(["x": .number(1), "y": .number(9)]),
            "b": .bool(true),
        ]))
    }
}
