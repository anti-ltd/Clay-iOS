/**
 The live preview: the shared `WidgetRecipeView` at exact family point size,
 ticking once a second so clocks run, on the ambient backdrop. A family
 switcher rides above it.
 */
import SwiftUI
import iUXiOS

struct EditorPreviewPane: View {
    @Bindable var editor: EditorModel

    private static let familyOptions: [(label: String, tag: WidgetFamilyKey)] = [
        ("Small", .small),
        ("Medium", .medium),
        ("Large", .large),
        ("Lock", .accessoryRectangular),
    ]

    var body: some View {
        VStack(spacing: 12) {
            OptionChips(options: Self.familyOptions, selection: $editor.previewFamily)
                .onChange(of: editor.previewFamily) { Haptics.light() }

            // Scale the widget to fit the space left below the chips. At exact
            // point size the Large family (382pt tall) overflows the pane and
            // shoves the chip row off the top edge — unreachable. GeometryReader
            // bounds the fit so every family stays inside and chips stay put.
            GeometryReader { geo in
                TimelineView(.periodic(from: .now, by: 1)) { timeline in
                    preview(date: timeline.date, available: geo.size)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .padding(.top, 8)
    }

    @ViewBuilder
    private func preview(date: Date, available: CGSize) -> some View {
        let family = editor.previewFamily
        let size = WidgetFamilyMetrics.pointSize(for: family)
        let scale = available.width > 0 && available.height > 0
            ? min(available.width / size.width, available.height / size.height, 1)
            : 1

        WidgetRecipeView(
            recipe: editor.draft,
            snapshot: .placeholder(date: date),
            family: family,
            isInWidget: false)
            .frame(width: size.width, height: size.height)
            .background {
                // Accessory preview gets a dim capsule backdrop standing in
                // for the lock screen's vibrant treatment.
                if family.isAccessory {
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(.white.opacity(0.12))
                }
            }
            .scaleEffect(scale)
            .frame(width: size.width * scale, height: size.height * scale)
            .animation(UX.Motion.morph, value: editor.draft.theme)
            .animation(UX.Motion.morph, value: family)
    }
}
