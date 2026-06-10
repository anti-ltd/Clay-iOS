/**
 The preset rail: every shipped theme as a mini widget thumbnail — the actual
 recipe rendered small by the shared renderer, not a color swatch. Tap =
 instant theme swap with a light haptic; the preview morphs.
 */
import SwiftUI
import iUXiOS

struct ThemeRail: View {
    @Bindable var editor: EditorModel

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                ForEach(ThemePresets.all) { preset in
                    ThemeThumb(
                        recipe: editor.draft,
                        preset: preset,
                        isSelected: editor.draft.theme.id == preset.id
                    ) {
                        editor.mutate { recipe in
                            recipe.theme = preset
                        }
                        Haptics.light()
                    }
                }
            }
            .padding(.horizontal, UX.screenPadding)
            .padding(.vertical, 8)
        }
    }
}

private struct ThemeThumb: View {
    let recipe: WidgetRecipe
    let preset: WidgetTheme
    let isSelected: Bool
    let select: () -> Void

    var body: some View {
        Button(action: select) {
            VStack(spacing: 5) {
                themedMini
                    .frame(width: 64, height: 64)
                    .allowsHitTesting(false)
                Text(preset.name)
                    .font(.caption2.weight(isSelected ? .semibold : .regular))
                    .foregroundStyle(isSelected ? .primary : .secondary)
            }
            .padding(6)
            .background {
                if isSelected {
                    RoundedRectangle(cornerRadius: UX.Glass.pillRadius, style: .continuous)
                        .fill(.white.opacity(0.10))
                        .overlay {
                            RoundedRectangle(cornerRadius: UX.Glass.pillRadius, style: .continuous)
                                .strokeBorder(Color.accentColor.opacity(0.7), lineWidth: 1)
                        }
                }
            }
        }
        .buttonStyle(GlassButtonStyle())
    }

    private var themedMini: some View {
        var preview = recipe
        preview.theme = preset
        return ScaledWidgetPreview(recipe: preview, fitWidth: 64)
    }
}
