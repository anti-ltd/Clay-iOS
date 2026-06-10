/**
 `WidgetRecipeView`: THE renderer. The same view renders the editor preview,
 the widget gallery thumbnails, and the actual timeline entries in the widget
 extension — that single code path is what makes in-app previews
 pixel-truthful.

 Semantics:
 - The recipe THEME's background paints the widget container (via
   `containerBackground` in the extension, a rounded rect in the app).
 - A block gets its own surface chrome only when its style OVERRIDE sets a
   background — "this block opts out of the shared canvas."
 - Accessory families skip backgrounds entirely (the system supplies the
   vibrant treatment) and render content monochrome.
 */
import SwiftUI
import iUXiOS

public struct WidgetRecipeView: View {
    let recipe: WidgetRecipe
    let snapshot: BlockDataSnapshot
    let family: WidgetFamilyKey
    let isInWidget: Bool

    public init(
        recipe: WidgetRecipe,
        snapshot: BlockDataSnapshot,
        family: WidgetFamilyKey,
        isInWidget: Bool
    ) {
        self.recipe = recipe
        self.snapshot = snapshot
        self.family = family
        self.isInWidget = isInWidget
    }

    public var body: some View {
        let arrangement = recipe.layout.arrangement(for: family)
        let core = blockStack(arrangement: arrangement, blocks: visibleBlocks(arrangement))
            .padding(arrangement.padding)
            .frame(maxWidth: .infinity, maxHeight: .infinity)

        // In the widget, WidgetKit owns the container: background comes from
        // containerBackground(for: .widget) in the entry view and the system
        // clips to its own shape (accessories get the vibrant treatment).
        // In-app, we ARE the container — paint, clip, and float exactly like
        // the real thing so overflowing content can't escape the canvas.
        if isInWidget || family.isAccessory {
            core
        } else {
            core
                .background {
                    ThemeBackground(spec: recipe.theme.background, tint: recipe.theme.tint)
                }
                .clipShape(containerShape)
                .shadow(
                    color: .black.opacity(UX.Glass.shadowOpacity * recipe.theme.depth),
                    radius: UX.Glass.shadowRadius * recipe.theme.depth,
                    y: UX.Glass.shadowY * recipe.theme.depth)
        }
    }

    private var containerShape: some Shape {
        RoundedRectangle(
            cornerRadius: recipe.theme.corner.radius,
            style: recipe.theme.corner.continuous ? .continuous : .circular)
    }

    private func visibleBlocks(_ arrangement: FamilyArrangement) -> [BlockInstance] {
        guard let ids = arrangement.visibleBlockIDs else {
            // Tiny accessory canvases default to the lead block (and skip
            // blocks the family can't show) rather than cramming the stack;
            // an explicit visibleBlockIDs always wins.
            let supported = recipe.blocks.filter { block in
                BlockRegistry.module(for: block.kind)?
                    .supportedFamilies.contains(family) ?? true
            }
            switch family {
            case .accessoryCircular, .accessoryInline:
                return Array(supported.prefix(1))
            default:
                return supported
            }
        }
        let byID = Dictionary(uniqueKeysWithValues: recipe.blocks.map { ($0.id, $0) })
        return ids.compactMap { byID[$0] }
    }

    @ViewBuilder
    private func blockStack(arrangement: FamilyArrangement, blocks: [BlockInstance]) -> some View {
        switch arrangement.axis {
        case .vertical:
            VStack(alignment: horizontalAlignment(arrangement.alignment), spacing: arrangement.spacing) {
                blockViews(blocks)
            }
        case .horizontal:
            HStack(alignment: .center, spacing: arrangement.spacing) {
                blockViews(blocks)
            }
        }
    }

    @ViewBuilder
    private func blockViews(_ blocks: [BlockInstance]) -> some View {
        ForEach(blocks) { instance in
            BlockInstanceView(
                instance: instance,
                theme: recipe.theme,
                snapshot: snapshot,
                context: BlockRenderContext(
                    family: family, isInWidget: isInWidget, instanceID: instance.id))
        }
    }

    private func horizontalAlignment(_ alignment: LayoutAlignment) -> HorizontalAlignment {
        switch alignment {
        case .leading: .leading
        case .center: .center
        case .trailing: .trailing
        }
    }
}

/// One block: registry render (or the unknown placeholder, or the permission
/// placeholder when a gated need is denied), wrapped in its own surface only
/// when the block's override sets a background.
struct BlockInstanceView: View {
    let instance: BlockInstance
    let theme: WidgetTheme
    let snapshot: BlockDataSnapshot
    let context: BlockRenderContext

    var body: some View {
        let style = ResolvedBlockStyle(theme: theme, override: instance.styleOverride)

        content(style: style)
            .modifier(BlockSurface(
                background: context.family.isAccessory ? nil : instance.styleOverride?.background,
                style: style))
    }

    @ViewBuilder
    private func content(style: ResolvedBlockStyle) -> some View {
        if let module = BlockRegistry.module(for: instance.kind) {
            if let requirement = module.permission,
               snapshot.deniedNeeds.contains(requirement.need) {
                PermissionPlaceholderBlock(
                    requirement: requirement, style: style, family: context.family)
            } else {
                module.render(
                    instance: instance,
                    style: style,
                    snapshot: snapshot,
                    context: context)
            }
        } else {
            UnknownBlockView(kind: instance.kind, style: style)
        }
    }
}

/// Per-block surface chrome, only for blocks that override their background.
private struct BlockSurface: ViewModifier {
    let background: BackgroundSpec?
    let style: ResolvedBlockStyle

    func body(content: Content) -> some View {
        if let background {
            content
                .padding(8)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background {
                    ThemeBackground(spec: background, tint: style.tint)
                        .clipShape(shape)
                }
                .overlay {
                    shape.strokeBorder(
                        .white.opacity(UX.Glass.outlineOpacity),
                        lineWidth: UX.Glass.outlineWidth)
                }
        } else {
            content
        }
    }

    private var shape: RoundedRectangle {
        RoundedRectangle(
            cornerRadius: style.corner.radius,
            style: style.corner.continuous ? .continuous : .circular)
    }
}
