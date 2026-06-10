/**
 The Blocks panel: the recipe's drag-ordered block list (the same order the
 layout stack renders), swipe-to-delete, tap to inspect, plus the add button
 opening the gallery sheet.
 */
import SwiftUI
import iUXiOS

struct BlockListPanel: View {
    @Bindable var editor: EditorModel
    @Binding var inspecting: BlockSelection?
    @State private var showingGallery = false

    var body: some View {
        List {
            ForEach(editor.draft.blocks) { block in
                BlockRow(block: block)
                    .contentShape(Rectangle())
                    .onTapGesture { inspecting = BlockSelection(id: block.id) }
                    .listRowBackground(Color.clear)
                    .listRowSeparatorTint(.white.opacity(0.08))
            }
            .onMove { source, destination in
                editor.moveBlocks(from: source, to: destination)
                Haptics.medium()
            }
            .onDelete { offsets in
                editor.removeBlocks(at: offsets)
                Haptics.medium()
            }

            Button {
                showingGallery = true
            } label: {
                Label("Add Block", systemImage: "plus.circle.fill")
                    .font(.subheadline.weight(.medium))
            }
            .buttonStyle(GlassButtonStyle())
            .listRowBackground(Color.clear)
            .listRowSeparator(.hidden)
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
        .environment(\.editMode, .constant(.active)) // always-on drag handles
        .sheet(isPresented: $showingGallery) {
            BlockGallerySheet(editor: editor)
        }
        .overlay {
            if editor.draft.blocks.isEmpty {
                EmptyStateCard(
                    symbol: "square.stack.3d.up",
                    title: "No blocks yet",
                    message: "Add a clock, date, weather and more.",
                    actionLabel: "Add Block") {
                        showingGallery = true
                    }
                    .padding(UX.screenPadding)
            }
        }
    }
}

private struct BlockRow: View {
    let block: BlockInstance

    private var module: BlockHandle? {
        BlockRegistry.module(for: block.kind)
    }

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: module?.systemImage ?? "questionmark.square.dashed")
                .font(.system(size: 16, weight: .medium))
                .foregroundStyle(.tint)
                .frame(width: 26)
            VStack(alignment: .leading, spacing: 1) {
                Text(module?.displayName ?? block.kind.rawValue.capitalized)
                    .font(.body)
                if block.styleOverride?.isEmpty == false {
                    Text("Custom style")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            Spacer()
            Image(systemName: "chevron.right")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.tertiary)
        }
        .padding(.vertical, 4)
    }
}
