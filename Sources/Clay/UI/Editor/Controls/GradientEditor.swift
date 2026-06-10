/**
 Two-stop gradient editor: end-point colors plus an angle slider, with a live
 strip preview. Deliberately simple for MVP — multi-stop editing can come
 later without a model change (GradientSpec already holds N stops).
 */
import SwiftUI
import iUXiOS

struct GradientEditor: View {
    @Binding var spec: GradientSpec

    private func stopBinding(_ index: Int) -> Binding<RGBA?> {
        Binding(
            get: { spec.stops.indices.contains(index) ? spec.stops[index].color : nil },
            set: { newValue in
                guard let newValue, spec.stops.indices.contains(index) else { return }
                spec.stops[index].color = newValue
            })
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            LinearGradientSpecView(spec: spec)
                .frame(height: 32)
                .clipShape(RoundedRectangle(cornerRadius: UX.Glass.pillRadius, style: .continuous))
                .overlay {
                    RoundedRectangle(cornerRadius: UX.Glass.pillRadius, style: .continuous)
                        .strokeBorder(.white.opacity(UX.Glass.outlineOpacity), lineWidth: UX.Glass.outlineWidth)
                }
                .padding(.vertical, 10)

            ColorPickerRow(label: "Start", rgba: stopBinding(0), allowsNone: false)
            Divider()
            ColorPickerRow(label: "End", rgba: stopBinding(1), allowsNone: false)
            Divider()
            SliderRow(
                "Angle",
                value: $spec.angleDegrees,
                in: 0...360,
                step: 5
            ) { "\(Int($0))°" }
        }
        .onAppear {
            // Guarantee exactly the two editable stops.
            if spec.stops.count < 2 {
                spec.stops = GradientSpec().stops
            }
        }
    }
}
