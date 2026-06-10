/**
 A recipe rendered at its TRUE family point size, then scaled to fit a target
 width — the only correct way to thumbnail a widget. Framing the renderer at
 an arbitrary small size instead lies about proportions and lets content
 overflow the card.
 */
import SwiftUI
import iUXiOS

struct ScaledWidgetPreview: View {
    let recipe: WidgetRecipe
    var family: WidgetFamilyKey = .small
    var fitWidth: CGFloat
    var snapshot: BlockDataSnapshot = .placeholder()

    var body: some View {
        let size = WidgetFamilyMetrics.pointSize(for: family)
        let scale = fitWidth / size.width

        WidgetRecipeView(
            recipe: recipe,
            snapshot: snapshot,
            family: family,
            isInWidget: false)
            .frame(width: size.width, height: size.height)
            .scaleEffect(scale)
            .frame(width: size.width * scale, height: size.height * scale)
            .allowsHitTesting(false)
    }
}
