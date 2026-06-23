/**
 Settings: permission status at a glance, the add-widget coach, and the about
 footer. Clay is offline-first — there's deliberately little to configure.
 */
import SwiftUI
import iUXiOS

struct SettingsView: View {
    @Environment(AppModel.self) private var model
    @State private var showingCoach = false
    @State private var stats = AquariumStats.empty

    private let gated: [PermissionRequirement] = BlockRegistry.all.compactMap(\.permission)

    var body: some View {
        ScrollView {
            VStack(spacing: UX.cardSpacing) {
                if stats.totalSwims > 0 {
                    CardSection("Aquarium") {
                        AquariumStatsCard(stats: stats, tankNames: tankNames) {
                            AnalyticsStore.shared.resetAquariumStats()
                            stats = .empty
                        }
                    }
                }

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
        .onAppear {
            model.permissions.refresh()
            stats = AnalyticsStore.shared.aquariumStats()
        }
    }

    /// Tank instance id → owning recipe name, for labelling per-tank counts.
    /// A recipe with several aquariums numbers them so rows stay distinct.
    private var tankNames: [String: String] {
        var names: [String: String] = [:]
        for recipe in model.recipes {
            let tanks = recipe.blocks.filter { $0.kind == .aquarium }
            for (i, tank) in tanks.enumerated() {
                names[tank.id.uuidString] = tanks.count > 1
                    ? "\(recipe.name) #\(i + 1)"
                    : recipe.name
            }
        }
        return names
    }
}

/// Private, on-device "how often did I make my fish swim" counters.
private struct AquariumStatsCard: View {
    let stats: AquariumStats
    let tankNames: [String: String]
    let onReset: () -> Void

    /// Per-tank rows, biggest first; tanks no longer in any recipe show last.
    private var rows: [(label: String, count: Int)] {
        stats.perTank
            .map { (tankNames[$0.key] ?? "Deleted tank", $0.value) }
            .sorted { $0.1 > $1.1 }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .firstTextBaseline) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("\(stats.totalSwims)")
                        .font(.largeTitle.weight(.bold))
                        .contentTransition(.numericText())
                    Text(stats.totalSwims == 1 ? "swim" : "swims")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Image(systemName: "fish")
                    .font(.title)
                    .foregroundStyle(.tint)
            }
            .padding(.vertical, UX.rowVPadding)

            if rows.count > 1 {
                ForEach(rows, id: \.label) { row in
                    Divider()
                    HStack {
                        Text(row.label)
                            .lineLimit(1)
                        Spacer()
                        Text("\(row.count)")
                            .foregroundStyle(.secondary)
                            .monospacedDigit()
                    }
                    .padding(.vertical, UX.rowVPadding)
                }
            }

            if let last = stats.lastSwimAt {
                Divider()
                HStack {
                    Text("Last swim")
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text(last.formatted(date: .abbreviated, time: .shortened))
                        .foregroundStyle(.secondary)
                }
                .font(.footnote)
                .padding(.vertical, UX.rowVPadding)
            }

            Divider()
            Button(role: .destructive, action: onReset) {
                Text("Reset count")
                    .padding(.vertical, UX.rowVPadding)
            }
            .buttonStyle(.plain)
        }
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
