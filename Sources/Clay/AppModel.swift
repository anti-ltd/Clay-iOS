import SwiftUI
import WidgetKit

@Observable
@MainActor
final class AppModel {
    /// The user's widget library — source of truth is the shared store; this
    /// is the app-process mirror.
    private(set) var recipes: [WidgetRecipe] = []

    let permissions = PermissionCenter()

    /// A `clay://enable/<need>` deep link (widget placeholder tap) waiting for
    /// its sheet.
    var pendingPermission: PermissionRequirement?

    @ObservationIgnored private let store: RecipeStore
    @ObservationIgnored private var observerToken: AnyObject?
    @ObservationIgnored private var reloadTask: Task<Void, Never>?

    init(store: RecipeStore = .shared) {
        self.store = store
        recipes = store.loadRecipes()
        seedIfEmpty()

        // Another process (or scene) changed the store — refresh the mirror.
        observerToken = store.observeRecipes { [weak self] in
            Task { @MainActor [weak self] in
                guard let self else { return }
                recipes = self.store.loadRecipes()
            }
        }
    }

    /// First launch: one beautiful recipe so the widget gallery, the system
    /// widget picker, and the editor all have something to show.
    private func seedIfEmpty() {
        guard recipes.isEmpty else { return }
        let starter = WidgetRecipe.starter()
        store.upsert(starter, notify: false)
        recipes = [starter]
    }

    // MARK: - CRUD (writes through to the shared store)

    func upsert(_ recipe: WidgetRecipe) {
        var updated = recipe
        updated.modifiedAt = .now
        store.upsert(updated, notify: false)
        recipes = store.loadRecipes()
        scheduleWidgetReload()
    }

    func delete(_ id: UUID) {
        store.delete(id: id, notify: false)
        recipes = store.loadRecipes()
        scheduleWidgetReload()
    }

    func duplicate(_ recipe: WidgetRecipe) {
        var copy = recipe
        copy.id = UUID()
        copy.name = "\(recipe.name) Copy"
        copy.createdAt = .now
        upsert(copy)
    }

    /// Debounced `WidgetCenter` reload — the actual app→extension bridge.
    /// Debounce so slider scrubbing in the editor doesn't spam the budget.
    private func scheduleWidgetReload() {
        reloadTask?.cancel()
        reloadTask = Task { @MainActor in
            try? await Task.sleep(for: .seconds(1))
            guard !Task.isCancelled else { return }
            WidgetCenter.shared.reloadAllTimelines()
        }
    }
}
