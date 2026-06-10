/**
 Unwraps a timeline entry into the shared `WidgetRecipeView` (the SAME view
 the in-app editor previews) and wires the container background and tap deep
 link. The missing-recipe state nudges into the app rather than rendering
 blank.
 */
import SwiftUI
import WidgetKit

struct RecipeEntryView: View {
    @Environment(\.widgetFamily) private var widgetFamily

    let entry: RecipeEntry

    private var familyKey: WidgetFamilyKey {
        switch widgetFamily {
        case .systemMedium: .medium
        case .systemLarge: .large
        case .accessoryRectangular: .accessoryRectangular
        case .accessoryCircular: .accessoryCircular
        case .accessoryInline: .accessoryInline
        default: .small
        }
    }

    var body: some View {
        if let recipe = entry.recipe {
            WidgetRecipeView(
                recipe: recipe,
                snapshot: entry.snapshot,
                family: familyKey,
                isInWidget: true)
                .widgetURL(widgetURL(for: recipe))
                .containerBackground(for: .widget) {
                    if !familyKey.isAccessory {
                        ThemeBackground(spec: recipe.theme.background, tint: recipe.theme.tint)
                    }
                }
        } else {
            MissingRecipeView(family: familyKey)
                .containerBackground(for: .widget) {
                    ThemeBackground(
                        spec: .gradient(GradientSpec()),
                        tint: RGBA(hex: 0x8B7CF8))
                }
        }
    }

    private func widgetURL(for recipe: WidgetRecipe) -> URL {
        // A denied gated block redirects the tap into its enable flow;
        // otherwise tapping opens the design in the editor.
        if let denied = entry.snapshot.deniedNeeds.first {
            return DeepLink.enable(denied.rawValue).url
        }
        return DeepLink.recipe(recipe.id).url
    }
}

private struct MissingRecipeView: View {
    let family: WidgetFamilyKey

    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: "sparkles.rectangle.stack")
                .font(.system(size: family.isAccessory ? 16 : 24, weight: .light))
            if family != .accessoryCircular {
                Text("Open Clay to create a design")
                    .font(.system(size: 12, weight: .medium, design: .rounded))
                    .multilineTextAlignment(.center)
            }
        }
        .foregroundStyle(family.isAccessory ? Color.primary : .white.opacity(0.85))
    }
}
