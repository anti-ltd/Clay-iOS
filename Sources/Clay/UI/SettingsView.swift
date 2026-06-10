/**
 Settings: permission status at a glance, the add-widget coach, and the about
 footer. Clay is offline-first — there's deliberately little to configure.
 */
import SwiftUI
import iUXiOS

struct SettingsView: View {
    @Environment(AppModel.self) private var model
    @State private var showingCoach = false

    private let gated: [PermissionRequirement] = BlockRegistry.all.compactMap(\.permission)

    var body: some View {
        ScrollView {
            VStack(spacing: UX.cardSpacing) {
                CardSection("Access") {
                    VStack(alignment: .leading, spacing: 0) {
                        ForEach(Array(gated.enumerated()), id: \.element.need) { index, requirement in
                            if index > 0 { Divider() }
                            PermissionStatusRow(requirement: requirement)
                        }
                    }
                }

                CardSection("Help") {
                    Button {
                        showingCoach = true
                    } label: {
                        HStack {
                            Label("How to add widgets", systemImage: "questionmark.circle")
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(.tertiary)
                        }
                        .padding(.vertical, UX.rowVPadding)
                    }
                    .buttonStyle(.plain)
                }

                Text("Clay runs entirely on your device.\nNo accounts, no tracking, no telemetry.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.top, 8)
            }
            .padding(UX.screenPadding)
        }
        .navigationTitle("Settings")
        .sheet(isPresented: $showingCoach) {
            AddToHomeScreenCoach()
        }
        .onAppear { model.permissions.refresh() }
    }
}

private struct PermissionStatusRow: View {
    @Environment(AppModel.self) private var model
    let requirement: PermissionRequirement

    var body: some View {
        Button {
            model.pendingPermission = requirement
        } label: {
            HStack {
                Label(requirement.title, systemImage: requirement.symbolName)
                Spacer()
                switch model.permissions.status(for: requirement.need) {
                case .granted:
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(.green)
                case .denied:
                    Text("Off")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                case .notDetermined:
                    Text("Set Up")
                        .font(.subheadline)
                        .foregroundStyle(.tint)
                }
            }
            .padding(.vertical, UX.rowVPadding)
        }
        .buttonStyle(.plain)
    }
}
