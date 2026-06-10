/**
 The widget-configuration intent: "which saved design does this widget slot
 show?" — the only mechanism iOS offers for binding user-created content to a
 widget. The entity query reads the shared `RecipeStore`, so the picker in the
 system's edit-widget UI always reflects the user's current library.
 */
import AppIntents
import WidgetKit

struct RecipeEntity: AppEntity, Identifiable {
    static let typeDisplayRepresentation: TypeDisplayRepresentation = "Widget Design"
    static let defaultQuery = RecipeQuery()

    var id: UUID
    var name: String

    var displayRepresentation: DisplayRepresentation {
        DisplayRepresentation(title: "\(name)")
    }

    init(recipe: WidgetRecipe) {
        self.id = recipe.id
        self.name = recipe.name
    }
}

struct RecipeQuery: EntityQuery {
    func entities(for identifiers: [UUID]) async throws -> [RecipeEntity] {
        let ids = Set(identifiers)
        return RecipeStore.shared.loadRecipes()
            .filter { ids.contains($0.id) }
            .map(RecipeEntity.init)
    }

    func suggestedEntities() async throws -> [RecipeEntity] {
        RecipeStore.shared.loadRecipes().map(RecipeEntity.init)
    }

    /// New widgets default to the first saved design instead of sitting blank.
    func defaultResult() async -> RecipeEntity? {
        RecipeStore.shared.loadRecipes().first.map(RecipeEntity.init)
    }
}

struct SelectRecipeIntent: WidgetConfigurationIntent {
    static let title: LocalizedStringResource = "Choose Design"
    static let description = IntentDescription("Pick which Clay design this widget shows.")

    @Parameter(title: "Design")
    var recipe: RecipeEntity?
}
