/**
 `RecipeStore`: the inter-process bridge. The app and the widget extension
 share recipes through JSON **files** in the App Group container — NOT App
 Group `UserDefaults`, whose cross-process reads are cached per-process by
 cfprefsd and go stale (the lesson learned in Clink). A fresh
 `Data(contentsOf:)` always reflects the latest bytes on disk.

 A Darwin notification is posted on save for app-side observers; the real
 app→extension bridge is `WidgetCenter.reloadTimelines` (extensions don't
 long-run observers), which the app calls debounced after every save.
 */
import Foundation

public final class RecipeStore: @unchecked Sendable {
    /// Darwin notification posted whenever the recipe list changes.
    public static let recipesDidChangeNotification = "ltd.anti.clay.recipesDidChange"

    public static let shared = RecipeStore()

    private let appGroupID: String

    public init(appGroupID: String = ClayKit.appGroupID) {
        self.appGroupID = appGroupID
    }

    private func containerURL() -> URL? {
        FileManager.default
            .containerURL(forSecurityApplicationGroupIdentifier: appGroupID)
    }

    // MARK: - Recipes

    /// `…/<AppGroup>/clay-recipes.v1.json`
    private var recipesFileURL: URL? {
        containerURL()?.appendingPathComponent("clay-recipes.v1.json")
    }

    public func loadRecipes() -> [WidgetRecipe] {
        if let url = recipesFileURL,
           let data = try? Data(contentsOf: url),
           let decoded = decodeRecipes(data) {
            return decoded
        }
        // App Group container unavailable (self-signed build without a matching
        // provisioning profile). Fall back to standard UserDefaults so recipes
        // at least survive within this process rather than resetting every time.
        if let data = UserDefaults.standard.data(forKey: "clay-recipes-v1"),
           let decoded = decodeRecipes(data) {
            return decoded
        }
        return []
    }

    /// Lossy list decode: one corrupt/foreign recipe must not blank the whole
    /// library. Individual recipes are already maximally defensive decoders;
    /// this guards the array layer.
    private func decodeRecipes(_ data: Data) -> [WidgetRecipe]? {
        guard let raw = try? JSONDecoder().decode([JSONValue].self, from: data) else { return nil }
        return raw.compactMap { $0.decoded(as: WidgetRecipe.self) }
    }

    /// Persist the full recipe list. `notify` posts the cross-process change
    /// notification; pass `false` for self-originated writes where the writer
    /// already updated its own live state and a reload would only churn.
    public func saveRecipes(_ recipes: [WidgetRecipe], notify: Bool = true) {
        if let url = recipesFileURL,
           let data = try? JSONEncoder().encode(recipes) {
            try? data.write(to: url, options: .atomic)
            if notify { post(Self.recipesDidChangeNotification) }
            return
        }
        if let data = try? JSONEncoder().encode(recipes) {
            UserDefaults.standard.set(data, forKey: "clay-recipes-v1")
        }
    }

    /// Read-modify-write convenience for a single recipe.
    public func upsert(_ recipe: WidgetRecipe, notify: Bool = true) {
        var recipes = loadRecipes()
        if let i = recipes.firstIndex(where: { $0.id == recipe.id }) {
            recipes[i] = recipe
        } else {
            recipes.append(recipe)
        }
        saveRecipes(recipes, notify: notify)
    }

    public func recipe(id: UUID) -> WidgetRecipe? {
        loadRecipes().first { $0.id == id }
    }

    public func delete(id: UUID, notify: Bool = true) {
        saveRecipes(loadRecipes().filter { $0.id != id }, notify: notify)
    }

    // MARK: - Cross-process change notifications

    private func post(_ name: String) {
        let center = CFNotificationCenterGetDarwinNotifyCenter()
        CFNotificationCenterPostNotification(
            center,
            CFNotificationName(name as CFString),
            nil, nil, true
        )
    }

    /// Register a callback fired when recipes change in another process. Keep
    /// the returned token alive for as long as you want the callback;
    /// releasing it automatically unregisters.
    public func observeRecipes(_ handler: @escaping @Sendable () -> Void) -> AnyObject {
        NotificationToken(name: Self.recipesDidChangeNotification, handler: handler)
    }

    public func stopObserving(_ token: AnyObject) {
        (token as? NotificationToken)?.unregister()
    }
}

/// Retains the Swift closure for the lifetime of a Darwin notification
/// registration (CFNotificationCenter only stores a raw pointer) and removes
/// the observer when it deallocates — so the caller just has to hold/drop it.
private final class NotificationToken: @unchecked Sendable {
    let handler: @Sendable () -> Void

    init(name: String, handler: @escaping @Sendable () -> Void) {
        self.handler = handler
        let center = CFNotificationCenterGetDarwinNotifyCenter()
        let observer = Unmanaged.passUnretained(self).toOpaque()
        CFNotificationCenterAddObserver(
            center, observer,
            { _, observer, _, _, _ in
                guard let observer else { return }
                Unmanaged<NotificationToken>.fromOpaque(observer)
                    .takeUnretainedValue().handler()
            },
            name as CFString, nil, .deliverImmediately
        )
    }

    func unregister() {
        let center = CFNotificationCenterGetDarwinNotifyCenter()
        CFNotificationCenterRemoveEveryObserver(center, Unmanaged.passUnretained(self).toOpaque())
    }

    deinit { unregister() }
}
