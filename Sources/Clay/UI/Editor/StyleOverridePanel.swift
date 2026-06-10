/**
 Per-block style overrides: each control mirrors a theme parameter, lighting
 up when the block deviates; "Reset to Theme" clears the lot. Background
 override gives the block its own surface chrome.
 */
import SwiftUI
import iUXiOS

struct StyleOverridePanel: View {
    @Binding var instance: BlockInstance
    let theme: WidgetTheme

    private var override: BlockStyleOverride {
        instance.styleOverride ?? BlockStyleOverride()
    }

    private func overrideBinding<T>(
        _ get: @escaping (BlockStyleOverride) -> T,
        _ set: @escaping (inout BlockStyleOverride, T) -> Void
    ) -> Binding<T> {
        Binding(
            get: { get(override) },
            set: { newValue in
                var updated = override
                set(&updated, newValue)
                instance.styleOverride = updated.isEmpty ? nil : updated
            })
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            ToggleRow(
                "Own Surface",
                subtitle: "Give this block its own glass card.",
                isOn: overrideBinding(
                    { $0.background != nil },
                    { override, isOn in
                        override.background = isOn ? .material(.ultraThin) : nil
                    }))
            Divider()
            ColorPickerRow(
                label: "Tint",
                rgba: overrideBinding({ $0.tint }, { $0.tint = $1 }))
            Divider()
            SliderRow(
                "Text Size",
                value: overrideBinding(
                    { $0.typography?.scale ?? theme.typography.scale },
                    { override, scale in
                        var typography = override.typography ?? theme.typography
                        typography.scale = scale
                        override.typography = typography
                    }),
                in: 0.7...1.5, step: 0.05
            ) { String(format: "%.2f×", $0) }
            Divider()
            ColorPickerRow(
                label: "Text Color",
                rgba: overrideBinding(
                    { $0.foreground?.primary },
                    { override, rgba in
                        if let rgba {
                            var foreground = override.foreground ?? ForegroundSpec()
                            foreground.primary = rgba
                            override.foreground = foreground
                        } else {
                            override.foreground = nil
                        }
                    }))

            if instance.styleOverride != nil {
                Divider()
                Button {
                    instance.styleOverride = nil
                    Haptics.light()
                } label: {
                    Label("Reset to Theme", systemImage: "arrow.uturn.backward.circle")
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(.tint)
                }
                .buttonStyle(GlassButtonStyle())
                .padding(.vertical, UX.rowVPadding)
            }
        }
    }
}
