import XCTest
@testable import Clay

/// Showcase content integrity: every built-in setup must round-trip, reference
/// only known block kinds and quote packs, and carry stable unique ids.
final class SetupTests: XCTestCase {
    func testShowcaseSetupsRoundTrip() throws {
        for setup in ShowcaseSetups.all {
            let data = try JSONEncoder().encode(setup)
            XCTAssertEqual(try JSONDecoder().decode(Setup.self, from: data), setup)
        }
    }

    func testShowcaseBlocksAreAllKnownKinds() {
        for setup in ShowcaseSetups.all {
            for recipe in setup.recipes {
                for block in recipe.blocks {
                    XCTAssertNotNil(
                        BlockRegistry.module(for: block.kind),
                        "\(setup.name)/\(recipe.name) references unknown kind \(block.kind.rawValue)")
                }
            }
        }
    }

    func testShowcaseQuotePackReferencesExist() throws {
        let packIDs = Set(QuotePacks.allPacks.map(\.id) + ["custom"])
        for setup in ShowcaseSetups.all {
            for recipe in setup.recipes {
                for block in recipe.blocks where block.kind == .quote {
                    let config = block.config.decoded(as: QuoteConfig.self, filling: QuoteConfig())
                    XCTAssertTrue(
                        packIDs.contains(config.packID),
                        "\(setup.name) references missing quote pack \(config.packID)")
                }
            }
        }
    }

    func testShowcaseIDsAreUniqueAndStable() {
        let setupIDs = ShowcaseSetups.all.map(\.id)
        XCTAssertEqual(setupIDs.count, Set(setupIDs).count)

        let recipeIDs = ShowcaseSetups.all.flatMap { $0.recipes.map(\.id) }
        XCTAssertEqual(recipeIDs.count, Set(recipeIDs).count)
    }

    func testBundledQuotePacksDecode() {
        // Packs ship in the app bundle; the suite host IS the app, so this
        // catches content regressions in CI.
        XCTAssertGreaterThanOrEqual(QuotePacks.allPacks.count, 3)
        for pack in QuotePacks.allPacks {
            XCTAssertFalse(pack.quotes.isEmpty, "pack \(pack.id) is empty")
        }
    }
}
