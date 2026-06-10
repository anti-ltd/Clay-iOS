import XCTest
@testable import Clay

final class RecipeCodableTests: XCTestCase {
    private func makeRecipe() -> WidgetRecipe {
        WidgetRecipe(
            name: "Morning Glass",
            blocks: [
                BlockInstance(
                    kind: .clock,
                    config: .object(["style": .string("analog"), "showsSeconds": .bool(false)]),
                    weight: 2),
                BlockInstance(
                    kind: .date,
                    styleOverride: BlockStyleOverride(tint: RGBA(hex: 0xFF8800)),
                    weight: 1),
            ],
            theme: WidgetTheme(
                id: "preset.midnight",
                name: "Midnight",
                background: .gradient(GradientSpec()),
                depth: 0.7,
                blur: 0.2,
                tint: RGBA(hex: 0x6D3FB8),
                typography: TypographySpec(scale: 1.2, design: "rounded", weight: "semibold"),
                corner: CornerSpec(radius: 20, continuous: true),
                foreground: ForegroundSpec(primary: RGBA(hex: 0xFFFFFF))),
            layout: RecipeLayout(arrangements: [
                .small: FamilyArrangement(axis: .vertical, spacing: 6, padding: 10),
                .medium: FamilyArrangement(axis: .horizontal),
            ]))
    }

    func testRecipeRoundTrip() throws {
        let recipe = makeRecipe()
        let data = try JSONEncoder().encode(recipe)
        let decoded = try JSONDecoder().decode(WidgetRecipe.self, from: data)
        XCTAssertEqual(decoded, recipe)
    }

    func testBackgroundSpecRoundTripsAllCases() throws {
        let specs: [BackgroundSpec] = [
            .material(.thick),
            .tint(RGBA(hex: 0x112233)),
            .gradient(GradientSpec(angleDegrees: 90)),
            .clear,
        ]
        for spec in specs {
            let data = try JSONEncoder().encode(spec)
            XCTAssertEqual(try JSONDecoder().decode(BackgroundSpec.self, from: data), spec)
        }
    }

    func testRecipeLayoutEncodesAsPlainObject() throws {
        let layout = RecipeLayout(arrangements: [.small: FamilyArrangement()])
        let data = try JSONEncoder().encode(layout)
        let object = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        XCTAssertNotNil(object?["small"], "layout should encode keyed by family raw value")
    }

    func testLayoutFallbackArrangements() {
        let layout = RecipeLayout()
        XCTAssertEqual(layout.arrangement(for: .small).axis, .vertical)
        XCTAssertEqual(layout.arrangement(for: .medium).axis, .horizontal)
        XCTAssertEqual(layout.arrangement(for: .accessoryInline).axis, .horizontal)
    }

    func testSetupRoundTrip() throws {
        let setup = Setup(
            name: "Glass Dawn",
            blurb: "A bright start.",
            recipes: [makeRecipe()],
            wallpaper: WallpaperSuggestion(assetName: "wallpaper-dawn", credit: "Anti"),
            isBuiltIn: true)
        let data = try JSONEncoder().encode(setup)
        XCTAssertEqual(try JSONDecoder().decode(Setup.self, from: data), setup)
    }

    func testRecipeStoreLossyArrayDecode() throws {
        // One valid recipe + one entry that isn't a recipe at all: the store
        // must keep the valid one rather than returning an empty library.
        let recipe = makeRecipe()
        let valid = try JSONValue(encoding: recipe)
        let garbage = JSONValue.string("not a recipe")
        let data = try JSONEncoder().encode([valid, garbage])

        // Exercise the same lossy path the store uses.
        let raw = try JSONDecoder().decode([JSONValue].self, from: data)
        let recipes = raw.compactMap { $0.decoded(as: WidgetRecipe.self) }
        XCTAssertEqual(recipes.count, 1)
        XCTAssertEqual(recipes.first?.id, recipe.id)
    }
}
