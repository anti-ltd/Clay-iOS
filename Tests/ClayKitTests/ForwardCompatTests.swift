import XCTest
@testable import Clay

/// The forward-compat contract: recipes written by NEWER app versions —
/// unknown block kinds, unknown fields, higher schema versions — must decode,
/// render harmlessly, and re-encode without destroying the future data.
final class ForwardCompatTests: XCTestCase {
    func testUnknownBlockKindDecodesAndSurvivesRoundTrip() throws {
        let json = """
        {
          "schemaVersion": 1,
          "id": "11111111-2222-3333-4444-555555555555",
          "name": "From The Future",
          "blocks": [
            { "kind": "clock", "config": { "style": "digital" } },
            { "kind": "hologram",
              "config": { "projector": "v2", "depthMap": [1, 2, 3] } }
          ],
          "theme": { "id": "preset.midnight", "name": "Midnight" }
        }
        """
        let recipe = try JSONDecoder().decode(WidgetRecipe.self, from: Data(json.utf8))
        XCTAssertEqual(recipe.blocks.count, 2)
        XCTAssertEqual(recipe.blocks[1].kind.rawValue, "hologram")

        // Re-encode and decode again: the unknown block's config must be intact.
        let reencoded = try JSONEncoder().encode(recipe)
        let again = try JSONDecoder().decode(WidgetRecipe.self, from: reencoded)
        XCTAssertEqual(
            again.blocks[1].config,
            .object(["projector": .string("v2"), "depthMap": .array([.number(1), .number(2), .number(3)])]))
    }

    func testHigherSchemaVersionStillDecodes() throws {
        let json = """
        { "schemaVersion": 99, "name": "Tomorrow",
          "blocks": [], "theme": { "id": "t", "name": "T" },
          "futureField": { "whatever": true } }
        """
        let recipe = try JSONDecoder().decode(WidgetRecipe.self, from: Data(json.utf8))
        XCTAssertEqual(recipe.schemaVersion, 99)
        XCTAssertEqual(recipe.name, "Tomorrow")
    }

    func testUnknownThemeFieldsAndBackgroundKindDegrade() throws {
        let json = """
        { "id": "preset.x", "name": "X",
          "background": { "kind": "plasma", "plasmaIntensity": 11 },
          "refraction": 0.5 }
        """
        let theme = try JSONDecoder().decode(WidgetTheme.self, from: Data(json.utf8))
        XCTAssertEqual(theme.background, .material(.ultraThin), "unknown background kind degrades to material")
    }

    func testMinimalRecipeDecodesWithDefaults() throws {
        let json = #"{ "name": "Bare", "theme": { "id": "t", "name": "T" } }"#
        let recipe = try JSONDecoder().decode(WidgetRecipe.self, from: Data(json.utf8))
        XCTAssertEqual(recipe.schemaVersion, 1)
        XCTAssertTrue(recipe.blocks.isEmpty)
        XCTAssertEqual(recipe.theme.depth, 0.5)
        XCTAssertEqual(recipe.theme.corner.radius, 16)
    }

    func testUnknownLayoutFamilyKeyIsSkippedNotFatal() throws {
        let json = """
        { "small": { "axis": "vertical" },
          "holoProjection": { "axis": "spherical" } }
        """
        let layout = try JSONDecoder().decode(RecipeLayout.self, from: Data(json.utf8))
        XCTAssertEqual(layout.arrangements.count, 1)
        XCTAssertNotNil(layout.arrangements[.small])
    }

    func testUnknownAxisDegradesToDefault() throws {
        let json = #"{ "axis": "diagonal", "spacing": 4 }"#
        let arrangement = try JSONDecoder().decode(FamilyArrangement.self, from: Data(json.utf8))
        XCTAssertEqual(arrangement.axis, .vertical)
        XCTAssertEqual(arrangement.spacing, 4)
    }
}
