/**
 A settings-row-styled ColorPicker bridging SwiftUI `Color` ↔ the model's
 `RGBA`, with an optional "none" clear affordance.

 Clay-local for now — flagged as an iUX-iOS promotion candidate (Clink's
 theme builder wants the same row).
 */
import SwiftUI
import iUXiOS

struct ColorPickerRow: View {
    let label: String
    @Binding var rgba: RGBA?
    var allowsNone = true

    var body: some View {
        HStack {
            Text(label)
            Spacer()
            if rgba != nil && allowsNone {
                Button {
                    rgba = nil
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(.tertiary)
                }
                .buttonStyle(.plain)
            }
            ColorPicker(
                label,
                selection: Binding(
                    get: { rgba?.color ?? .white },
                    set: { rgba = RGBA($0) }),
                supportsOpacity: true)
                .labelsHidden()
        }
        .padding(.vertical, UX.rowVPadding)
    }
}
