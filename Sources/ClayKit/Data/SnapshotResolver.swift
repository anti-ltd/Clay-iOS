/**
 `SnapshotResolver`: turns a recipe's union of data needs into a complete
 `BlockDataSnapshot` as of a given date — called by the widget timeline
 provider once per entry, and by the editor's live ticker in-app. Providers
 are injected so tests stub them and phase 6 adds the real EventKit /
 WeatherKit / HealthKit / battery / photo / quote sources one by one.

 Providers degrade, never throw: a failed fetch yields `nil` data, a missing
 permission lands the need in `deniedNeeds` (→ the "tap to enable" block).
 */
import Foundation

/// One data source. Implementations cache aggressively (App Group files) so
/// N timeline entries don't mean N system queries.
public protocol SnapshotProviding: Sendable {
    var need: DataNeed { get }
    /// Contribute to the snapshot. `recipe` lets per-instance needs (photo
    /// shuffle, quote selection) key their choices by block id.
    func contribute(
        to snapshot: inout BlockDataSnapshot,
        recipe: WidgetRecipe,
        at date: Date
    ) async
}

public struct SnapshotResolver: Sendable {
    private let providers: [any SnapshotProviding]

    public init(providers: [any SnapshotProviding] = []) {
        self.providers = providers
    }

    /// The full production lineup — used by the widget timeline provider and
    /// the app's live preview alike.
    public static func standard() -> SnapshotResolver {
        SnapshotResolver(providers: [
            BatteryProvider(),
            PhotoSelectionProvider(),
            QuoteSelectionProvider(),
            EventProvider(),
            WeatherProvider(),
            StepsProvider(),
        ])
    }

    /// The union of data needs across a recipe's known blocks.
    public nonisolated static func needs(of recipe: WidgetRecipe) -> Set<DataNeed> {
        var needs: Set<DataNeed> = []
        for block in recipe.blocks {
            if let module = BlockRegistry.module(for: block.kind) {
                needs.formUnion(module.dataNeeds)
            }
        }
        return needs
    }

    public func resolve(for recipe: WidgetRecipe, at date: Date) async -> BlockDataSnapshot {
        var snapshot = BlockDataSnapshot(date: date)
        let needs = Self.needs(of: recipe)
        for provider in providers where needs.contains(provider.need) {
            await provider.contribute(to: &snapshot, recipe: recipe, at: date)
        }
        return snapshot
    }
}
