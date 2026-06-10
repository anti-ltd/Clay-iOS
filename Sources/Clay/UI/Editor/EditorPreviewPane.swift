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

            Spacer(minLength: 0)

            TimelineView(.periodic(from: .now, by: 1)) { timeline in
                preview(date: timeline.date)
            }

            Spacer(minLength: 0)
        }
        .padding(.top, 8)
    }

    @ViewBuilder
    private func preview(date: Date) -> some View {
        let family = editor.previewFamily
        let size = WidgetFamilyMetrics.pointSize(for: family)

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
            .animation(UX.Motion.morph, value: editor.draft.theme)
            .animation(UX.Motion.morph, value: family)
    }
}
