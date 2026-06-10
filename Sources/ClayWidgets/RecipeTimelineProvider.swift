/**
 The timeline provider for both widget kinds: load the configured recipe from
 the shared store → ask `RecipeTimelineBuilder` for the merged entry plan →
 resolve one `BlockDataSnapshot` per entry date. Rendering happens later, on
 the main actor, from pre-resolved value types.
 */
import WidgetKit

struct RecipeEntry: TimelineEntry {
    let date: Date
    let recipe: WidgetRecipe?
    let snapshot: BlockDataSnapshot
}

struct RecipeTimelineProvider: AppIntentTimelineProvider {
    private var resolver: SnapshotResolver { .standard() }

    private func configuredRecipe(_ configuration: SelectRecipeIntent) -> WidgetRecipe? {
        if let id = configuration.recipe?.id {
            return RecipeStore.shared.recipe(id: id)
        }
        return RecipeStore.shared.loadRecipes().first
    }

    func placeholder(in context: Context) -> RecipeEntry {
        RecipeEntry(
            date: .now,
            recipe: RecipeStore.shared.loadRecipes().first ?? .starter(),
            snapshot: .placeholder())
    }

    func snapshot(for configuration: SelectRecipeIntent, in context: Context) async -> RecipeEntry {
        let recipe = configuredRecipe(configuration) ?? .starter()
        let snapshot = await resolver.resolve(for: recipe, at: .now)
        return RecipeEntry(date: .now, recipe: recipe, snapshot: snapshot)
    }

    func timeline(for configuration: SelectRecipeIntent, in context: Context) async -> Timeline<RecipeEntry> {
        guard let recipe = configuredRecipe(configuration) else {
            // No designs yet: a quiet nudge, re-checked hourly.
            let entry = RecipeEntry(date: .now, recipe: nil, snapshot: BlockDataSnapshot(date: .now))
            return Timeline(entries: [entry], policy: .after(.now.addingTimeInterval(3600)))
        }

        let plan = RecipeTimelineBuilder.plan(for: recipe, now: .now)
        var entries: [RecipeEntry] = []
        for date in plan.entryDates {
            let snapshot = await resolver.resolve(for: recipe, at: date)
            entries.append(RecipeEntry(date: date, recipe: recipe, snapshot: snapshot))
        }

        let policy: TimelineReloadPolicy =
            plan.reloadAfter.map { .after($0) } ?? .atEnd
        return Timeline(entries: entries, policy: policy)
    }
}
