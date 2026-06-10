/**
 Setups: full looks — widgets + wallpaper pairing. Showcase content sells the
 first-run experience; each card previews its recipes live.
 */
import SwiftUI
import iUXiOS

struct SetupsView: View {
    var body: some View {
        ScrollView {
            VStack(spacing: UX.cardSpacing) {
                ForEach(ShowcaseSetups.all) { setup in
                    NavigationLink(value: setup.id) {
                        SetupCard(setup: setup)
                    }
                    .buttonStyle(GlassButtonStyle())
                }
            }
            .padding(UX.screenPadding)
        }
        .navigationTitle("Setups")
        .navigationDestination(for: UUID.self) { setupID in
            if let setup = ShowcaseSetups.all.first(where: { $0.id == setupID }) {
                SetupDetailView(setup: setup)
            }
        }
    }
}

private struct SetupCard: View {
    let setup: Setup

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 10) {
                ForEach(setup.recipes.prefix(2)) { recipe in
                    ScaledWidgetPreview(recipe: recipe, fitWidth: 133)
                }
                Spacer(minLength: 0)
            }
            .frame(maxWidth: .infinity)
            .padding(.top, 4)

            VStack(alignment: .leading, spacing: 3) {
                Text(setup.name)
                    .font(.headline)
                    .foregroundStyle(.primary)
                Text(setup.blurb)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.leading)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background {
            if let gradient = setup.wallpaper?.gradient {
                LinearGradientSpecView(spec: gradient)
                    .opacity(0.5)
                    .clipShape(RoundedRectangle(cornerRadius: UX.Glass.cardRadius, style: .continuous))
            }
        }
        .glassCard()
    }
}
