/**
 `ThemeBackground`: paints a `BackgroundSpec` — the widget container fill, and
 the surface of any block that overrides its background. Material treatments
 layer the iUX glass idiom (tint wash, sheen, lit rim) over the system material
 so Clay widgets read unmistakably as family.
 */
import SwiftUI
import iUXiOS

public struct ThemeBackground: View {
    let spec: BackgroundSpec
    let tint: RGBA?

    public init(spec: BackgroundSpec, tint: RGBA? = nil) {
        self.spec = spec
        self.tint = tint
    }

    public var body: some View {
        switch spec {
        case .material(let kind):
            materialFill(kind)
        case .tint(let rgba):
            rgba.color
        case .gradient(let gradient):
            LinearGradientSpecView(spec: gradient)
        case .clear:
            Color.clear
        }
    }

    @ViewBuilder
    private func materialFill(_ kind: MaterialKind) -> some View {
        Rectangle()
            .fill(material(for: kind))
            .overlay {
                // Brand-tint wash from the top-leading corner — the iUX
                // glass signature (UX.Glass.tintWashOpacity).
                if let tint {
                    LinearGradient(
                        colors: [
                            tint.color.opacity(UX.Glass.tintWashOpacity),
                            .clear,
                        ],
                        startPoint: .topLeading, endPoint: .bottomTrailing)
                }
            }
            .overlay {
                // Sheen highlight.
                LinearGradient(
                    colors: [
                        .white.opacity(UX.Glass.sheenTopOpacity),
                        .white.opacity(UX.Glass.sheenMidOpacity),
                        .clear,
                    ],
                    startPoint: .top, endPoint: .center)
            }
    }

    private func material(for kind: MaterialKind) -> Material {
        switch kind {
        case .thin: .thinMaterial
        case .regular: .regularMaterial
        case .thick: .thickMaterial
        default: .ultraThinMaterial
        }
    }
}

/// A `GradientSpec` as a SwiftUI gradient, honoring the design-tool angle
/// convention (0° = bottom→top, 90° = leading→trailing).
public struct LinearGradientSpecView: View {
    let spec: GradientSpec

    public init(spec: GradientSpec) {
        self.spec = spec
    }

    public var body: some View {
        let radians = (spec.angleDegrees - 90) * .pi / 180
        let dx = cos(radians) / 2, dy = sin(radians) / 2
        return LinearGradient(
            stops: spec.stops.map { .init(color: $0.color.color, location: $0.location) },
            startPoint: UnitPoint(x: 0.5 - dx, y: 0.5 - dy),
            endPoint: UnitPoint(x: 0.5 + dx, y: 0.5 + dy))
    }
}
