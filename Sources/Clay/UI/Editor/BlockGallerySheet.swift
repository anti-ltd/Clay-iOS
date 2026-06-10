/**
 The block gallery: every registered module as a glass tile, rendered with
 placeholder data so each tile is a real preview of the block, not an icon
 grid. Tiles gray out for blocks the previewed family can't show.
 */
import SwiftUI
import iUXiOS

struct BlockGallerySheet: View {
    @Bindable var editor: EditorModel
    @Environment(AppModel.self) private var model
    @Environment(\.dismiss) private var dismiss

    private let columns = [GridItem(.adaptive(minimum: 150), spacing: UX.cardSpacing)]

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVGrid(columns: columns, spacing: UX.cardSpacing) {
                    ForEach(BlockRegistry.all.indices, id: \.self) { index in
                        let module = BlockRegistry.all[index]
                        BlockGalleryTile(
                            module: module,
                            theme: editor.draft.theme,
                            supported: module.supportedFamilies.contains(editor.previewFamily)
                        ) {
                            editor.addBlock(kind: module.kind)
                            Haptics.medium()
                            // Gated block: pitch + request right away so the
                            // preview fills with real data, not a placeholder.
                            if let requirement = module.permission,
                               model.permissions.status(for: requirement.need) != .granted {
                                model.pendingPermission = requirement
                            }
                            dismiss()
                        }
                    }
                }
                .padding(UX.screenPadding)
            }
            .navigationTitle("Add Block")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
        .glassSheet()
    }
}

private struct BlockGalleryTile: View {
    let module: BlockHandle
    let theme: WidgetTheme
    let supported: Bool
    let add: () -> Void

    var body: some View {
        Button(action: add) {
            VStack(spacing: 10) {
                module.render(
                    instance: BlockInstance(kind: module.kind, config: module.defaultConfig),
                    style: ResolvedBlockStyle(theme: theme),
                    snapshot: .placeholder(),
                    context: BlockRenderContext(family: .small, isInWidget: false))
                    .frame(height: 72)
                    .allowsHitTesting(false)

                Label(module.displayName, systemImage: module.systemImage)
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(.primary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .glassTile()
        }
        .buttonStyle(GlassButtonStyle())
        .disabled(!supported)
        .opacity(supported ? 1 : 0.35)
    }
}
