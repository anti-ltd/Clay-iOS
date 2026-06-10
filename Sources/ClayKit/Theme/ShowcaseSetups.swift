/**
 The built-in showcase Setups — the first-run experience and the App Store
 screenshots. Code constants (the ThemePresets rationale): they're design
 artifacts, and recipe literals in Swift are type-checked where JSON would
 rot. Fixed UUIDs so re-applying a setup is idempotent in tests.
 */
import Foundation

public enum ShowcaseSetups {
    public static let all: [Setup] = [
        midnightHours, glassDesk, emberEvenings, fieldNotes, neonGrid, paperback,
    ]

    private static func recipe(
        _ seed: String, _ name: String, theme: WidgetTheme,
        blocks: [BlockInstance], layout: RecipeLayout = RecipeLayout()
    ) -> WidgetRecipe {
        WidgetRecipe(
            id: UUID(uuidString: seed) ?? UUID(),
            name: name, blocks: blocks, theme: theme, layout: layout)
    }

    private static func block(_ seed: String, _ kind: BlockKind, config: JSONValue = .object([:]), weight: Double = 1) -> BlockInstance {
        BlockInstance(id: UUID(uuidString: seed) ?? UUID(), kind: kind, config: config, weight: weight)
    }

    // MARK: - Setups

    public static let midnightHours = Setup(
        id: UUID(uuidString: "A0000000-0000-4000-8000-000000000001")!,
        name: "Midnight Hours",
        blurb: "A deep indigo lock-up: analog time, the date, and tomorrow at a glance.",
        recipes: [
            recipe("A1000000-0000-4000-8000-000000000001", "Midnight Clock",
                   theme: ThemePresets.midnight,
                   blocks: [
                       block("A1100000-0000-4000-8000-000000000001", .clock,
                             config: .object(["style": .string("analog"), "showsSeconds": .bool(false), "showsTicks": .bool(true)]),
                             weight: 2),
                       block("A1100000-0000-4000-8000-000000000002", .date),
                   ]),
            recipe("A1000000-0000-4000-8000-000000000002", "Midnight Agenda",
                   theme: ThemePresets.midnight,
                   blocks: [
                       block("A1200000-0000-4000-8000-000000000001", .calendar),
                   ]),
        ],
        wallpaper: WallpaperSuggestion(
            gradient: GradientSpec(
                stops: [
                    .init(color: RGBA(hex: 0x0A0918), location: 0),
                    .init(color: RGBA(hex: 0x2A2452), location: 1),
                ],
                angleDegrees: 20)),
        isBuiltIn: true)

    public static let glassDesk = Setup(
        id: UUID(uuidString: "A0000000-0000-4000-8000-000000000002")!,
        name: "Glass Desk",
        blurb: "Frosted essentials: weather, battery, and the time in pure glass.",
        recipes: [
            recipe("A2000000-0000-4000-8000-000000000001", "Frost Status",
                   theme: ThemePresets.frost,
                   blocks: [
                       block("A2100000-0000-4000-8000-000000000001", .weather, weight: 2),
                       block("A2100000-0000-4000-8000-000000000002", .battery),
                   ],
                   layout: RecipeLayout(arrangements: [
                       .small: FamilyArrangement(axis: .vertical),
                       .medium: FamilyArrangement(axis: .horizontal, spacing: 14),
                   ])),
            recipe("A2000000-0000-4000-8000-000000000002", "Frost Time",
                   theme: ThemePresets.frost,
                   blocks: [
                       block("A2200000-0000-4000-8000-000000000001", .clock),
                       block("A2200000-0000-4000-8000-000000000002", .date,
                             config: .object(["arrangement": .string("inline")])),
                   ]),
        ],
        wallpaper: WallpaperSuggestion(
            gradient: GradientSpec(
                stops: [
                    .init(color: RGBA(hex: 0x44506B), location: 0),
                    .init(color: RGBA(hex: 0x9BB3D4), location: 1),
                ],
                angleDegrees: 0)),
        isBuiltIn: true)

    public static let emberEvenings = Setup(
        id: UUID(uuidString: "A0000000-0000-4000-8000-000000000003")!,
        name: "Ember Evenings",
        blurb: "Warm serif glow with a countdown to what's next.",
        recipes: [
            recipe("A3000000-0000-4000-8000-000000000001", "Ember Countdown",
                   theme: ThemePresets.ember,
                   blocks: [
                       block("A3100000-0000-4000-8000-000000000001", .countdown, weight: 2),
                       block("A3100000-0000-4000-8000-000000000002", .date,
                             config: .object(["arrangement": .string("inline")])),
                   ]),
            recipe("A3000000-0000-4000-8000-000000000002", "Ember Words",
                   theme: ThemePresets.ember,
                   blocks: [
                       block("A3200000-0000-4000-8000-000000000001", .quote,
                             config: .object(["packID": .string("calm")])),
                   ]),
        ],
        wallpaper: WallpaperSuggestion(
            gradient: GradientSpec(
                stops: [
                    .init(color: RGBA(hex: 0x190705), location: 0),
                    .init(color: RGBA(hex: 0x4A1B0C), location: 1),
                ],
                angleDegrees: 30)),
        isBuiltIn: true)

    public static let fieldNotes = Setup(
        id: UUID(uuidString: "A0000000-0000-4000-8000-000000000004")!,
        name: "Field Notes",
        blurb: "Pine green health and habits: steps, weather, and momentum.",
        recipes: [
            recipe("A4000000-0000-4000-8000-000000000001", "Pine Steps",
                   theme: ThemePresets.pine,
                   blocks: [
                       block("A4100000-0000-4000-8000-000000000001", .steps, weight: 2),
                       block("A4100000-0000-4000-8000-000000000002", .weather),
                   ],
                   layout: RecipeLayout(arrangements: [
                       .medium: FamilyArrangement(axis: .horizontal, spacing: 14),
                   ])),
            recipe("A4000000-0000-4000-8000-000000000002", "Pine Momentum",
                   theme: ThemePresets.pine,
                   blocks: [
                       block("A4200000-0000-4000-8000-000000000001", .quote,
                             config: .object(["packID": .string("momentum")])),
                   ]),
        ],
        wallpaper: WallpaperSuggestion(
            gradient: GradientSpec(
                stops: [
                    .init(color: RGBA(hex: 0x081209), location: 0),
                    .init(color: RGBA(hex: 0x16341D), location: 1),
                ],
                angleDegrees: 75)),
        isBuiltIn: true)

    public static let neonGrid = Setup(
        id: UUID(uuidString: "A0000000-0000-4000-8000-000000000005")!,
        name: "Neon Grid",
        blurb: "Terminal-teal mono: digital time, battery, and steps like a HUD.",
        recipes: [
            recipe("A5000000-0000-4000-8000-000000000001", "Neon Time",
                   theme: ThemePresets.neon,
                   blocks: [
                       block("A5100000-0000-4000-8000-000000000001", .clock, weight: 2),
                       block("A5100000-0000-4000-8000-000000000002", .date,
                             config: .object(["arrangement": .string("inline")])),
                   ]),
            recipe("A5000000-0000-4000-8000-000000000002", "Neon Vitals",
                   theme: ThemePresets.neon,
                   blocks: [
                       block("A5200000-0000-4000-8000-000000000001", .battery),
                       block("A5200000-0000-4000-8000-000000000002", .steps),
                   ],
                   layout: RecipeLayout(arrangements: [
                       .small: FamilyArrangement(axis: .horizontal, spacing: 10),
                       .medium: FamilyArrangement(axis: .horizontal, spacing: 18),
                   ])),
        ],
        wallpaper: WallpaperSuggestion(
            gradient: GradientSpec(
                stops: [
                    .init(color: RGBA(hex: 0x03030A), location: 0),
                    .init(color: RGBA(hex: 0x0A1F2E), location: 1),
                ],
                angleDegrees: 90)),
        isBuiltIn: true)

    public static let paperback = Setup(
        id: UUID(uuidString: "A0000000-0000-4000-8000-000000000006")!,
        name: "Paperback",
        blurb: "Warm paper and serif type — a quiet, literary home screen.",
        recipes: [
            recipe("A6000000-0000-4000-8000-000000000001", "Paper Date",
                   theme: ThemePresets.paper,
                   blocks: [
                       block("A6100000-0000-4000-8000-000000000001", .date, weight: 2),
                       block("A6100000-0000-4000-8000-000000000002", .calendar),
                   ]),
            recipe("A6000000-0000-4000-8000-000000000002", "Paper Words",
                   theme: ThemePresets.paper,
                   blocks: [
                       block("A6200000-0000-4000-8000-000000000001", .quote,
                             config: .object(["packID": .string("classic")])),
                   ]),
        ],
        wallpaper: WallpaperSuggestion(
            gradient: GradientSpec(
                stops: [
                    .init(color: RGBA(hex: 0xEDE7DB), location: 0),
                    .init(color: RGBA(hex: 0xD9CDB8), location: 1),
                ],
                angleDegrees: 0)),
        isBuiltIn: true)
}
