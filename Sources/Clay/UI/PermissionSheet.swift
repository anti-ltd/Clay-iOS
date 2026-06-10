/**
 The pre-permission pitch: a glass card explaining what the block needs and
 why, with the request CTA — the system prompt only fires after an explicit
 tap. Denied state routes to Settings.
 */
import SwiftUI
import iUXiOS

struct PermissionSheet: View {
    @Environment(AppModel.self) private var model
    @Environment(\.dismiss) private var dismiss

    let requirement: PermissionRequirement
    @State private var requesting = false

    var body: some View {
        VStack(spacing: UX.cardSpacing) {
            EmptyStateCard(
                symbol: requirement.symbolName,
                title: requirement.title,
                message: requirement.explanation + " Nothing leaves your device.")

            switch model.permissions.status(for: requirement.need) {
            case .granted:
                Label("Enabled", systemImage: "checkmark.circle.fill")
                    .font(.headline)
                    .foregroundStyle(.green)
                    .padding(.vertical, 12)
            case .denied:
                Button {
                    if let url = URL(string: UIApplication.openSettingsURLString) {
                        UIApplication.shared.open(url)
                    }
                } label: {
                    Text("Open Settings")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .glassPill(tint: .accentColor)
                }
                .buttonStyle(GlassButtonStyle())
            case .notDetermined:
                Button {
                    requesting = true
                    Task {
                        await model.permissions.request(requirement.need)
                        requesting = false
                        if model.permissions.status(for: requirement.need) == .granted {
                            Haptics.success()
                            dismiss()
                        }
                    }
                } label: {
                    HStack {
                        if requesting { ProgressView().tint(.white) }
                        Text("Enable \(requirement.title)")
                            .font(.headline)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .glassPill(tint: .accentColor)
                }
                .buttonStyle(GlassButtonStyle())
                .disabled(requesting)
            }
        }
        .padding(UX.screenPadding)
        .presentationDetents([.medium])
        .glassSheet()
    }
}
