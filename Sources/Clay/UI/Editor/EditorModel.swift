/**
 `EditorModel`: the draft state behind the composer. Value-type recipes make
 undo trivial — every mutation snapshots the previous draft. Edits autosave
 (debounced at the AppModel layer for widget reloads), so the editor always
 feels live; undo is the safety net instead of a discard dialog.
 */
import SwiftUI

@Observable
@MainActor
final class EditorModel {
    private(set) var draft: WidgetRecipe
    private(set) var undoStack: [WidgetRecipe] = []

    @ObservationIgnored private let commit: (WidgetRecipe) -> Void

    /// Family being previewed; the editor's panels follow it (layout edits
    /// apply to the selected family's arrangement).
    var previewFamily: WidgetFamilyKey = .small

    init(recipe: WidgetRecipe, commit: @escaping (WidgetRecipe) -> Void) {
        self.draft = recipe
        self.commit = commit
    }

    var canUndo: Bool { !undoStack.isEmpty }

    /// All mutations flow through here: snapshot → mutate → autosave.
    func mutate(_ change: (inout WidgetRecipe) -> Void) {
        undoStack.append(draft)
        if undoStack.count > 50 { undoStack.removeFirst() }
        change(&draft)
        commit(draft)
    }

    func undo() {
        guard let previous = undoStack.popLast() else { return }
        draft = previous
        commit(draft)
    }

    // MARK: - Block operations

    func addBlock(kind: BlockKind) {
        guard let module = BlockRegistry.module(for: kind) else { return }
        mutate { recipe in
            recipe.blocks.append(BlockInstance(kind: kind, config: module.defaultConfig))
        }
    }

    func removeBlocks(at offsets: IndexSet) {
        mutate { $0.blocks.remove(atOffsets: offsets) }
    }

    func moveBlocks(from source: IndexSet, to destination: Int) {
        mutate { $0.blocks.move(fromOffsets: source, toOffset: destination) }
    }

    /// Binding into one block for the inspector (config editor + overrides).
    func blockBinding(id: UUID) -> Binding<BlockInstance>? {
        guard draft.blocks.contains(where: { $0.id == id }) else { return nil }
        return Binding(
            get: { [weak self] in
                self?.draft.blocks.first { $0.id == id } ?? BlockInstance(kind: .clock)
            },
            set: { [weak self] newValue in
                // Guard before mutate: a write racing a deletion must not
                // push a no-op undo snapshot.
                guard let self,
                      draft.blocks.contains(where: { $0.id == id }) else { return }
                mutate { recipe in
                    if let index = recipe.blocks.firstIndex(where: { $0.id == id }) {
                        recipe.blocks[index] = newValue
                    }
                }
            })
    }

    // MARK: - Layout operations

    var currentArrangement: FamilyArrangement {
        draft.layout.arrangement(for: previewFamily)
    }

    func updateArrangement(_ change: (inout FamilyArrangement) -> Void) {
        mutate { recipe in
            var arrangement = recipe.layout.arrangement(for: previewFamily)
            change(&arrangement)
            recipe.layout.arrangements[previewFamily] = arrangement
        }
    }
}
