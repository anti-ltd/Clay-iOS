/**
 The block inspector: the module's own config editor inside a CardSection,
 plus the block's layout weight. Style overrides join in phase 7.
 */
import SwiftUI
import iUXiOS

struct BlockInspectorView: View {
    @Bindable var editor: EditorModel
    let blockID: UUID

    var body: some View {
        if let binding = editor.blockBinding(id: blockID),
           let module = BlockRegistry.module(for: binding.wrappedValue.kind) {
            ScrollView {
                VStack(spacing: UX.cardSpacing) {
                    CardSection(module.displayName) {
                        module.configEditor(instance: binding)
                    }

                    CardSection("Style") {
                        StyleOverridePanel(instance: binding, theme: editor.draft.theme)
                    }

                    CardSection("Layout") {
                        SliderRow(
                            "Size",
                            tooltip: "This block's share of the widget, relative to the others.",
                            value: Binding(
                                get: { binding.wrappedValue.weight },
                                set: { binding.wrappedValue.weight = $0 }),
                            in: 0.5...3,
                            step: 0.25
                        ) { value in
                            String(format: "%.2g×", value)
                        }
                    }
                }
                .padding(UX.screenPadding)
            }
            .navigationTitle(module.displayName)
            .navigationBarTitleDisplayMode(.inline)
        } else {
            EmptyStateCard(
                symbol: "questionmark.square.dashed",
                title: "Block unavailable",
                message: "This block was made in a newer version of Clay.")
                .padding(UX.screenPadding)
        }
    }
}
