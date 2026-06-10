# Clay Architecture

Clay is a widget studio: users compose widgets from styled blocks, theme every
visual layer, and add them to home and lock screens via WidgetKit. This
document covers the three load-bearing designs — the recipe model, the block
plugin pattern, and the timeline strategy — plus the process topology they
live in.

## Process topology

Two processes, isolated by iOS, sharing state only through the App Group
`group.ltd.anti.clay`:

```
┌─────────────── Clay (app) ───────────────┐   ┌──────── ClayWidgets ────────┐
│ editor, gallery, setups, permissions     │   │ timeline provider + entry   │
│ AppModel / EditorModel (@Observable)     │   │ views (same renderer)       │
└───────────────┬──────────────────────────┘   └──────────────┬──────────────┘
                │            App Group container              │
                └──>  clay-recipes.v1.json   (RecipeStore) <──┘
                      clay-photos/<uuid>.jpg (PhotoStore)
                      clay-weather-cache.v1.json, clay-steps-cache.v1.json
```

- **Files, not App Group UserDefaults.** cfprefsd caches suite reads
  per-process, so cross-process reads go stale (the lesson from Clink). A
  fresh `Data(contentsOf:)` always reflects the latest bytes. Writes are
  atomic; standard UserDefaults is the fallback when the container is
  unavailable (unprovisioned dev builds).
- **Change propagation is asymmetric.** Saves post a Darwin notification for
  *app-side* observers (other scenes). The app→extension bridge is
  `WidgetCenter.reloadAllTimelines()`, debounced ~1s in `AppModel` so slider
  scrubbing doesn't burn the WidgetKit budget — extensions can't hold
  long-running observers, so notifications would be useless there.
- Shared code is `Sources/ClayKit`, compiled into **both** targets (no dynamic
  framework — no extension rpath/embedding pitfalls). Module boundary is a
  folder convention, not a compiler wall.

## The recipe model

A widget = `WidgetRecipe` = ordered blocks + theme + per-family layout:

```
WidgetRecipe
├── blocks: [BlockInstance]        order = render order = editor list order
│   ├── kind: BlockKind            string-backed struct, NOT an enum
│   ├── config: JSONValue          opaque any-JSON; typed at use sites
│   ├── styleOverride?             all-Optional mirror of the theme
│   └── weight                     share of the layout axis
├── theme: WidgetTheme             background/depth/blur/tint/typography/corner/foreground
└── layout: RecipeLayout           [WidgetFamilyKey: FamilyArrangement]
                                   (axis, spacing, padding, alignment, visible blocks)
```

### Forward compatibility is a contract, not a hope

Recipes written by NEWER app versions must open in older ones. Enforced by
`ForwardCompatTests`:

- `BlockKind` is a `RawRepresentable` string struct: unknown kinds decode,
  render `UnknownBlockView` ("Update Clay"), and re-encode **losslessly** —
  `config` stays an opaque `JSONValue`, so saving from an old build never
  destroys a new block's data. An enum would fail the whole recipe decode.
- Every model decodes field-by-field with defaults (`decodeIfPresent`);
  `schemaVersion > current` still decodes best-effort.
- The store decodes the recipe array lossily (`[JSONValue]` → compactMap):
  one corrupt entry can't blank the library.

### Style resolution

Renderers never see the theme and the override separately —
`ResolvedBlockStyle(theme:override:)` merges override-over-theme once, and is
the only style type a block renderer receives. The theme's background paints
the widget container; a block gets its own surface chrome only when its
*override* sets a background ("this block opts out of the shared canvas").
Accessory families skip backgrounds entirely and render content monochrome —
the system supplies the vibrant treatment.

## The block plugin pattern

One module per block kind, one file per module (`Sources/ClayKit/Blocks/<Kind>/`),
following Cling's `PinModule` precedent:

```swift
protocol BlockModule {
    associatedtype Config: Codable & Hashable & Sendable
    nonisolated static var kind / displayName / systemImage / defaultConfig
                          / supportedFamilies / dataNeeds / permission
    @MainActor  static func render(config:style:snapshot:context:) -> AnyView
    nonisolated static func timelineNeed(config:) -> TimelineNeed
    @MainActor  static func configEditor(config: Binding<Config>) -> AnyView
}
```

- **Isolation split**: metadata + `timelineNeed` are `nonisolated` pure values
  (the timeline provider reads them off-main); `render`/`configEditor` are
  `@MainActor` (SwiftUI body is MainActor in both processes).
- **Erasure is a value type, not an existential.** `BlockHandle` is built
  generically from the module and carries closures that bridge the opaque
  `JSONValue` config to the typed `Config` (falling back to `defaultConfig`
  on mismatch — a newer config never crashes an older renderer). We tried a
  composed existential metatype (`any (BlockModule & AnyBlockModule).Type`)
  first; it crashes Swift 6's SILGen.
- `BlockRegistry.module(for:)` returns `nil` for unknown kinds — kinds come
  from data, so no `fatalError` (unlike `PinRegistry`, whose types come from
  code).
- `AnyView` at the boundary is deliberate: heterogeneous registry, tiny view
  trees, wholesale re-render by WidgetKit — no diffing win to protect.

**Adding a block** = one new file conforming to `BlockModule` + one line in
`BlockRegistry.all`. If it needs runtime data, add a `DataNeed` case and a
`SnapshotProviding` implementation; if it's permission-gated, fill in
`permission` and `PermissionCenter.request` — the placeholder, deep link, and
pitch UI compose automatically.

## Shared rendering — the pixel-truth invariant

`WidgetRecipeView` is THE renderer: editor preview, gallery thumbnails, theme
rail minis, and actual timeline entries all go through the same view, at real
family point sizes (`WidgetFamilyMetrics`).

What makes that safe is the data rule: **renderers are pure functions of
(config, style, snapshot, context)**. They never call `Date()`, never query a
framework, never await. All runtime data is resolved BEFORE rendering into a
Codable/Sendable `BlockDataSnapshot`:

- in the extension: by the timeline provider, once per entry date
- in the app: by the live preview ticker (placeholder data) — same code path

`SnapshotResolver` fans out to `SnapshotProviding` implementations, filtered
by the recipe's union of `dataNeeds`. Providers **degrade, never throw**: a
failed fetch yields stale-cached or nil data; a missing permission lands the
need in `snapshot.deniedNeeds`, which the recipe view renders as the themed
"tap to enable" placeholder (with `widgetURL` → `clay://enable/<need>` → the
in-app request flow). Granted-but-empty is NOT denied — blocks render their
own empty states.

Photos cross the process boundary as files: the app downscales picks to
≤1200px JPEG in `<AppGroup>/clay-photos/`, configs carry filenames only, the
extension reads bytes itself (widget memory cap ~30MB). Orphans are swept
against the set of referenced filenames.

## Timeline / refresh strategy

Each block declares a `TimelineNeed` from its config; `RecipeTimelineBuilder`
(pure, unit-tested) merges them into one plan:

| Block | Need | Why |
|---|---|---|
| Clock (digital) | `.selfUpdatingText` | `Text(_, style: .time)` live-updates free |
| Clock (analog) | `.perMinute` | drawn hands need dated entries — batched 60, 1h horizon |
| Date | `.at([next midnight])` | one boundary |
| Calendar | `.every(30m)` | refresh floor; events re-resolve per entry |
| Weather | `.every(30m)` | cache below makes this cheap |
| Battery | `.staticEntry` | widgets *can't* observe battery; sampled at reload (UI copy says so) |
| Photo single / shuffle | `.staticEntry` / `.every(1h)` | shuffle pick is deterministic per hour |
| Countdown | `.at([target])` | `Text(timerInterval:)` ticks; boundary flips "done" |
| Quote | `.every(24h)` or static | deterministic per-day pick |
| Steps | `.every(30m)` | cache below |

Merge rules: entry dates = now ∪ minute grid ∪ boundaries ∪ periodic grids,
**capped at 60 entries**; horizon 1h when per-minute else 24h; reload =
`.after(shortest periodic interval)`, else `.atEnd` with future entries, else
a lazy 4h re-plan (a single-entry `.atEnd` timeline would be instantly
reload-eligible).

Budget discipline beyond the merge:
- **Weather cache** (`clay-weather-cache.v1.json`, 25-min TTL): N entries ≠ N
  network calls; offline falls back to stale.
- **Steps cache**: HealthKit reads fail while the device is locked — exactly
  when lock-screen widgets refresh — so the last reading is cached and reused
  same-day. "Denied" is only inferred when there's no cache at all (HealthKit
  hides read-authorization status by design).
- **Deterministic shuffles** (quote/photo) are seeded from the entry date +
  the block UUID's raw bytes (`UUID.stableSeed`) — `hashValue` is randomized
  per process and would desync app and extension.

## Widget configuration

`AppIntentConfiguration` + `SelectRecipeIntent` (`@Parameter var recipe:
RecipeEntity?`) is the only iOS mechanism for binding user-created content to
a widget slot: `RecipeQuery` enumerates the shared store in the system's
edit-widget picker, and `defaultResult()` returns the first design so new
widgets are never blank. Two widget kinds: `ClayHome` (small/medium/large) and
`ClayLock` (accessory families — separate kind because accessories render
vibrant/monochrome and default to different arrangements).

**Platform honesty**: apps cannot place widgets or set wallpapers. The
`AddToHomeScreenCoach` sheet teaches the manual flow and is offered everywhere
recipes appear; wallpaper pairings save to Photos instead of pretending.

## Editor

`EditorModel` owns a draft `WidgetRecipe`; every mutation flows through
`mutate(_:)` which snapshots the previous value (value-type undo, 50 deep) and
autosaves through `AppModel.upsert` (debounced widget reload). The screen is
the shared preview at exact family size over a `GlassPanel` tool area —
Blocks (reorder list + gallery sheet), Layout (per-previewed-family
arrangement), Theme (preset rail + every parameter). Editing a preset theme
re-stamps its id `custom.<uuid>` so presets stay pristine.

## Testing

All logic tests live in `Tests/ClayKitTests` and run via `make test`: model
round-trips, the forward-compat fixtures (unknown kind, unknown fields,
`schemaVersion: 99`, lossless re-encode), JSONValue exhaustive round-trip,
style-resolution matrix, timeline merge cases (entry cap, midnight boundary,
mixed needs, reload policy), registry integrity, and showcase-content
integrity (every built-in setup round-trips, references only known kinds and
existing quote packs, ids unique).

## iUX-iOS usage and promotion candidates

All UI composes iUX primitives: `UX` tokens, glass surfaces
(`glassCard/Tile/Pill/Panel/Sheet`), `GlassButtonStyle`, `CardSection` +
rows/chips/sliders/steppers, `FlowLayout`, `AmbientBackdrop`, `ToolStrip`,
and the widget-safe Glance components (`CountdownText`, `EmptyStateCard`,
`GlassThumb`).

Built Clay-local, proposed for promotion into iUX-iOS once proven here:
- **ColorPickerRow** — settings-row `ColorPicker` with RGBA bridging and a
  "none" affordance (Clink's theme builder wants the same row).
- **`UX.TypeScale` typography tokens** — Clay's `TypographySpec` (scale ×
  design × weight) is app-level; a shared token set in `Theme/Tokens.swift`
  would align all three apps.

Deliberately staying local: `GradientEditor` (niche), `WidgetFamilyMetrics`
(widget-domain), `AddToHomeScreenCoach` (Clay UX).
