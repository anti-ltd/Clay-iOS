/**
 The composer — the product. Live preview on top, a dark-glass tool area
 below, an iUX ToolStrip switching panels. Every edit autosaves and animates;
 undo lives in the toolbar.
 */
import SwiftUI
import iUXiOS

struct EditorView: View {
    @Environment(AppModel.self) private var model

    @State private var editor: EditorModel
    @State private var toolSelection: String? = "blocks"
    @State private var inspecting: BlockSelection?

    private static let tools = [
        ToolItem(id: "blocks", title: "Blocks", systemImage: "square.stack.3d.up"),
        ToolItem(id: "layout", title: "Layout", systemImage: "rectangle.grid.1x2"),
        ToolItem(id: "theme", title: "Theme", systemImage: "paintbrush"),
    ]

    init(recipe: WidgetRecipe, model: AppModel) {
        _editor = State(initialValue: EditorModel(recipe: recipe) { [weak model] draft in
            model?.upsert(draft)
        })
    }

    var body: some View {
        VStack(spacing: 0) {
            EditorPreviewPane(editor: editor)
                .frame(maxHeight: .infinity)

            VStack(spacing: 0) {
                ToolStrip(items: Self.tools, selection: $toolSelection)
                    .padding(.top, 6)

                panel
                    .frame(height: 290)
            }
            .glassPanel(padding: 0)
            .padding(.horizontal, UX.overlayInset)
            .padding(.bottom, UX.overlayInset)
        }
        .navigationTitle(editor.draft.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    editor.undo()
                    Haptics.light()
                } label: {
                    Image(systemName: "arrow.uturn.backward")
                }
                .disabled(!editor.canUndo)
            }
        }
        .navigationDestination(item: $inspecting) { selection in
            BlockInspectorView(editor: editor, blockID: selection.id)
        }
        .ambientBackground(tint: editor.draft.theme.tint?.color)
    }

    @ViewBuilder
    private var panel: some View {
        switch toolSelection {
        case "layout":
            LayoutPanel(editor: editor)
        case "theme":
            ThemeEditorPanel(editor: editor)
        default:
            BlockListPanel(editor: editor, inspecting: $inspecting)
        }
    }
}

/// Identifiable wrapper so a block id can drive `navigationDestination(item:)`.
struct BlockSelection: Identifiable, Hashable {
    let id: UUID
}
