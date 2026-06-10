import XCTest
@testable import Clay

final class StyleResolutionTests: XCTestCase {
    private let theme = WidgetTheme(
        id: "preset.base",
        name: "Base",
        background: .material(.thin),
        depth: 0.4,
        blur: 0.1,
        tint: RGBA(hex: 0x6D3FB8),
        typography: TypographySpec(scale: 1, design: "default", weight: "regular"),
        corner: CornerSpec(radius: 16, continuous: true),
        foreground: ForegroundSpec())

    func testNoOverrideTakesEverythingFromTheme() {
        let style = ResolvedBlockStyle(theme: theme, override: nil)
        XCTAssertEqual(style.background, .material(.thin))
        XCTAssertEqual(style.depth, 0.4)
        XCTAssertEqual(style.tint, RGBA(hex: 0x6D3FB8))
        XCTAssertEqual(style.corner.radius, 16)
    }

    func testOverrideWinsFieldByField() {
        let override = BlockStyleOverride(
            depth: 0.9,
            tint: RGBA(hex: 0xFF0000),
            corner: CornerSpec(radius: 4, continuous: false))
        let style = ResolvedBlockStyle(theme: theme, override: override)
        // Overridden fields.
        XCTAssertEqual(style.depth, 0.9)
        XCTAssertEqual(style.tint, RGBA(hex: 0xFF0000))
        XCTAssertEqual(style.corner.radius, 4)
        // Untouched fields stay themed.
        XCTAssertEqual(style.background, .material(.thin))
        XCTAssertEqual(style.blur, 0.1)
        XCTAssertEqual(style.typography.scale, 1)
    }

    func testEmptyOverrideDetection() {
        XCTAssertTrue(BlockStyleOverride().isEmpty)
        XCTAssertFalse(BlockStyleOverride(depth: 0.2).isEmpty)
    }
}
