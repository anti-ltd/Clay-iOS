import SwiftUI
import iUXiOS

struct RootView: View {
    @Environment(AppModel.self) private var model
    @State private var path = NavigationPath()
    @State private var tab = "widgets"
    @AppStorage("hasSeenWelcome") private var hasSeenWelcome = false
    @State private var showingWelcome = false

    var body: some View {
        TabView(selection: $tab) {
            NavigationStack(path: $path) {
                WidgetGalleryView(path: $path)
                    .navigationDestination(for: UUID.self) { recipeID in
                        if let recipe = model.recipes.first(where: { $0.id == recipeID }) {
                            EditorView(recipe: recipe, model: model)
                        }
                    }
            }
            .tabItem { Label("Widgets", systemImage: "square.grid.2x2") }
            .tag("widgets")

            NavigationStack {
                SetupsView()
            }
            .tabItem { Label("Setups", systemImage: "sparkles.rectangle.stack") }
            .tag("setups")

            NavigationStack {
                SettingsView()
            }
            .tabItem { Label("Settings", systemImage: "gearshape") }
            .tag("settings")
        }
        .ambientBackground(tint: Color(red: 0.55, green: 0.49, blue: 0.97))
        .sheet(item: Binding(
            get: { model.pendingPermission.map { PermissionPresentation(requirement: $0) } },
            set: { presentation in
                if presentation == nil {
                    Bindable(model).pendingPermission.wrappedValue = nil
                }
            })
        ) { presentation in
            PermissionSheet(requirement: presentation.requirement)
        }
        .fullScreenCover(isPresented: $showingWelcome) {
            OnboardingView()
                .onDisappear { hasSeenWelcome = true }
        }
        .onAppear {
            if !hasSeenWelcome { showingWelcome = true }
        }
        .onOpenURL { url in
            guard let link = DeepLink(url: url) else { return }
            switch link {
            case .recipe(let id):
                tab = "widgets"
                path = NavigationPath()
                path.append(id)
            case .enable(let raw):
                guard let need = DataNeed(rawValue: raw),
                      let requirement = BlockRegistry.all
                        .compactMap(\.permission)
                        .first(where: { $0.need == need })
                else { return }
                model.pendingPermission = requirement
            }
        }
    }
}

private struct PermissionPresentation: Identifiable {
    let requirement: PermissionRequirement
    var id: DataNeed { requirement.need }
}
