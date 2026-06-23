/**
 My Widgets: every saved design rendered live by the shared renderer, tap to
 edit, long-press for duplicate/delete. The "+" makes a fresh design from the
 starter recipe shape.
 */
import SwiftUI
import iUXiOS

struct WidgetGalleryView: View {
    @Environment(AppModel.self) private var model
    @Binding var path: NavigationPath

    private let columns = [GridItem(.adaptive(minimum: 160), spacing: UX.cardSpacing)]

    var body: some View {
        ScrollView {
            LazyVGrid(columns: columns, spacing: UX.cardSpacing) {
                ForEach(model.recipes) { recipe in
                    NavigationLink(value: recipe.id) {
                        RecipeCard(recipe: recipe)
                    }
                    .buttonStyle(.plain)
                    .contextMenu {
                            Button {
                                model.duplicate(recipe)
                            } label: {
                                Label("Duplicate", systemImage: "plus.square.on.square")
                            }
                            Button(role: .destructive) {
                                model.delete(recipe.id)
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                        }
                }
            }
            .padding(UX.screenPadding)
        }
        .overlay {
            if model.recipes.isEmpty {
                EmptyStateCard(
                    symbol: "sparkles.rectangle.stack",
                    title: "No designs yet",
                    message: "Create your first widget and dress your phone.",
                    actionLabel: "New Widget") {
                        createNew()
                    }
                    .padding(UX.screenPadding)
            }
        }
        .navigationTitle("My Widgets")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    createNew()
                } label: {
                    Image(systemName: "plus")
                }
            }
        }
    }

    private func createNew() {
        var fresh = WidgetRecipe.starter()
        fresh.id = UUID()
        fresh.name = "Widget \(model.recipes.count + 1)"
        fresh.createdAt = .now
        model.upsert(fresh)
        Haptics.success()
        path.append(fresh.id)
    }
}

private struct RecipeCard: View {
    let recipe: WidgetRecipe

    var body: some View {
        VStack(spacing: 10) {
            ScaledWidgetPreview(recipe: recipe, fitWidth: 130)

            Text(recipe.name)
                .font(.subheadline.weight(.medium))
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .glassTile()
    }
}
