import SwiftUI
import WidgetKit

@main
struct ClayWidgetsBundle: WidgetBundle {
    var body: some Widget {
        ClayHomeWidget()
        ClayLockWidget()
    }
}

/// Home screen widget: one kind covering small/medium/large; the user picks
/// which saved design each instance shows via the edit-widget sheet.
struct ClayHomeWidget: Widget {
    var body: some WidgetConfiguration {
        AppIntentConfiguration(
            kind: "ClayHome",
            intent: SelectRecipeIntent.self,
            provider: RecipeTimelineProvider()
        ) { entry in
            RecipeEntryView(entry: entry)
        }
        .configurationDisplayName("Clay Widget")
        .description("A widget you designed in Clay.")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
    }
}

/// Lock screen widget: separate kind because accessory families render in the
/// system's vibrant/monochrome treatment and default to different
/// arrangements (typically a single block).
struct ClayLockWidget: Widget {
    var body: some WidgetConfiguration {
        AppIntentConfiguration(
            kind: "ClayLock",
            intent: SelectRecipeIntent.self,
            provider: RecipeTimelineProvider()
        ) { entry in
            RecipeEntryView(entry: entry)
        }
        .configurationDisplayName("Clay Lock Screen")
        .description("A lock screen widget you designed in Clay.")
        .supportedFamilies([.accessoryRectangular, .accessoryCircular, .accessoryInline])
    }
}
