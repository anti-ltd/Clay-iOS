/**
 The Layout panel: per-family arrangement controls — axis, spacing, padding,
 alignment — applying to the family currently previewed, so what you tune is
 what you see.
 */
import SwiftUI
import iUXiOS

struct LayoutPanel: View {
    @Bindable var editor: EditorModel

    var body: some View {
        ScrollView {
            VStack(spacing: UX.cardSpacing) {
                CardSection("\(editor.previewFamily.displayName) Arrangement") {
                    VStack(alignment: .leading, spacing: 0) {
                        OptionChips(
                            options: [("Stacked", LayoutAxis.vertical), ("Side by Side", LayoutAxis.horizontal)],
                            selection: Binding(
                                get: { editor.currentArrangement.axis },
                                set: { axis in editor.updateArrangement { $0.axis = axis } }))
                            .padding(.vertical, UX.rowVPadding)
                        Divider()
                        SliderRow(
                            "Spacing",
                            value: Binding(
                                get: { editor.currentArrangement.spacing },
                                set: { spacing in editor.updateArrangement { $0.spacing = spacing } }),
                            in: 0...24,
                            step: 1
                        ) { String(format: "%.0f", $0) }
                        Divider()
                        SliderRow(
                            "Padding",
                            value: Binding(
                                get: { editor.currentArrangement.padding },
                                set: { padding in editor.updateArrangement { $0.padding = padding } }),
                            in: 0...28,
                            step: 1
                        ) { String(format: "%.0f", $0) }
                        Divider()
                        OptionChips(
                            options: [
                                ("Leading", LayoutAlignment.leading),
                                ("Center", LayoutAlignment.center),
                                ("Trailing", LayoutAlignment.trailing),
                            ],
                            selection: Binding(
                                get: { editor.currentArrangement.alignment },
                                set: { alignment in editor.updateArrangement { $0.alignment = alignment } }))
                            .padding(.vertical, UX.rowVPadding)
                    }
                }
            }
            .padding(UX.screenPadding)
        }
    }
}
