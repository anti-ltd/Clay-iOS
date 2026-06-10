/**
 The Theme panel: preset rail up top, then every theme parameter editable —
 background treatment, depth, tint, typography, corner geometry, foreground.
 Editing a preset re-stamps the id as custom: presets stay pristine.
 */
import SwiftUI
import iUXiOS

struct ThemeEditorPanel: View {
    @Bindable var editor: EditorModel

    private func themeBinding<T>(
        _ get: @escaping (WidgetTheme) -> T,
        _ set: @escaping (inout WidgetTheme, T) -> Void
    ) -> Binding<T> {
        Binding(
            get: { get(editor.draft.theme) },
            set: { newValue in
                editor.mutate { recipe in
                    set(&recipe.theme, newValue)
                    if recipe.theme.id.hasPrefix("preset.") {
                        recipe.theme.id = "custom.\(UUID().uuidString)"
                        recipe.theme.name = "Custom"
                    }
                }
            })
    }

    private var backgroundKind: Binding<String> {
        themeBinding({ theme in
            switch theme.background {
            case .material: "material"
            case .tint: "color"
            case .gradient: "gradient"
            case .clear: "clear"
            }
        }, { theme, kind in
            switch kind {
            case "color": theme.background = .tint(theme.tint ?? RGBA(hex: 0x14122E))
            case "gradient": theme.background = .gradient(GradientSpec())
            case "clear": theme.background = .clear
            default: theme.background = .material(.ultraThin)
            }
        })
    }

    var body: some View {
        ScrollView {
            VStack(spacing: UX.cardSpacing) {
                ThemeRail(editor: editor)

                CardSection("Background") {
                    VStack(alignment: .leading, spacing: 0) {
                        OptionChips(
                            options: [
                                ("Glass", "material"), ("Color", "color"),
                                ("Gradient", "gradient"), ("None", "clear"),
                            ],
                            selection: backgroundKind)
                            .padding(.vertical, UX.rowVPadding)
                        backgroundDetail
                        Divider()
                        SliderRow("Depth", tooltip: "Floating shadow strength.",
                                  value: themeBinding({ $0.depth }, { $0.depth = $1 }),
                                  in: 0...1) { "\(Int($0 * 100))%" }
                        Divider()
                        ColorPickerRow(
                            label: "Tint",
                            rgba: themeBinding({ $0.tint }, { $0.tint = $1 }))
                    }
                }

                CardSection("Typography") {
                    VStack(alignment: .leading, spacing: 0) {
                        OptionChips(
                            options: [
                                ("Default", "default"), ("Rounded", "rounded"),
                                ("Serif", "serif"), ("Mono", "monospaced"),
                            ],
                            selection: themeBinding({ $0.typography.design }, { $0.typography.design = $1 }))
                            .padding(.vertical, UX.rowVPadding)
                        Divider()
                        OptionChips(
                            options: [
                                ("Light", "light"), ("Regular", "regular"),
                                ("Medium", "medium"), ("Semibold", "semibold"), ("Bold", "bold"),
                            ],
                            selection: themeBinding({ $0.typography.weight }, { $0.typography.weight = $1 }))
                            .padding(.vertical, UX.rowVPadding)
                        Divider()
                        SliderRow("Size",
                                  value: themeBinding({ $0.typography.scale }, { $0.typography.scale = $1 }),
                                  in: 0.7...1.5, step: 0.05) { String(format: "%.2f×", $0) }
                    }
                }

                CardSection("Corners") {
                    VStack(alignment: .leading, spacing: 0) {
                        SliderRow("Radius",
                                  value: themeBinding({ $0.corner.radius }, { $0.corner.radius = $1 }),
                                  in: 0...36, step: 1) { "\(Int($0))" }
                        Divider()
                        ToggleRow("Squircle", subtitle: "Continuous Apple-style corners.",
                                  isOn: themeBinding({ $0.corner.continuous }, { $0.corner.continuous = $1 }))
                    }
                }

                CardSection("Text Color") {
                    VStack(alignment: .leading, spacing: 0) {
                        ColorPickerRow(
                            label: "Primary",
                            rgba: themeBinding({ $0.foreground.primary }, { $0.foreground.primary = $1 }))
                        Divider()
                        ColorPickerRow(
                            label: "Secondary",
                            rgba: themeBinding({ $0.foreground.secondary }, { $0.foreground.secondary = $1 }))
                    }
                }
            }
            .padding(.bottom, UX.screenPadding)
        }
    }

    @ViewBuilder
    private var backgroundDetail: some View {
        switch editor.draft.theme.background {
        case .material:
            Divider()
            OptionChips(
                options: [
                    ("Ultra Thin", "ultraThin"), ("Thin", "thin"),
                    ("Regular", "regular"), ("Thick", "thick"),
                ],
                selection: themeBinding({ theme in
                    if case .material(let kind) = theme.background { kind.rawValue } else { "ultraThin" }
                }, { theme, raw in
                    theme.background = .material(MaterialKind(rawValue: raw))
                }))
                .padding(.vertical, UX.rowVPadding)
        case .tint:
            Divider()
            ColorPickerRow(
                label: "Color",
                rgba: themeBinding({ theme in
                    if case .tint(let rgba) = theme.background { rgba } else { nil }
                }, { theme, rgba in
                    if let rgba { theme.background = .tint(rgba) }
                }))
        case .gradient(let gradient):
            Divider()
            GradientEditor(spec: Binding(
                get: {
                    if case .gradient(let current) = editor.draft.theme.background { current } else { gradient }
                },
                set: { newValue in
                    editor.mutate { recipe in
                        recipe.theme.background = .gradient(newValue)
                        if recipe.theme.id.hasPrefix("preset.") {
                            recipe.theme.id = "custom.\(UUID().uuidString)"
                            recipe.theme.name = "Custom"
                        }
                    }
                }))
        case .clear:
            EmptyView()
        }
    }
}
