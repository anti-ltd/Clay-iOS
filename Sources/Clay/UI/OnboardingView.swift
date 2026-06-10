/**
 First run: the pitch in one screen — a live themed widget doing its thing,
 then straight into the gallery. Shown once (persisted flag). Colors are
 explicit (not .primary/.secondary): this screen IS the brand's dark glass,
 whatever the system scheme says.
 */
import SwiftUI
import iUXiOS

struct OnboardingView: View {
    @Environment(\.dismiss) private var dismiss

    private static let brand = Color(red: 0.55, green: 0.49, blue: 0.97)

    var body: some View {
        VStack(spacing: 0) {
            Spacer(minLength: 40)

            TimelineView(.periodic(from: .now, by: 1)) { timeline in
                WidgetRecipeView(
                    recipe: .starter(),
                    snapshot: .placeholder(date: timeline.date),
                    family: .small,
                    isInWidget: false)
                    .frame(
                        width: WidgetFamilyMetrics.pointSize(for: .small).width,
                        height: WidgetFamilyMetrics.pointSize(for: .small).height)
            }
            .shadow(color: Self.brand.opacity(0.35), radius: 36, y: 14)

            VStack(spacing: 14) {
                Text("Clay")
                    .font(.system(size: 40, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)

                Text("Dress your whole phone in minutes.")
                    .font(.headline)
                    .foregroundStyle(.white.opacity(0.9))

                Text("Compose widgets from styled blocks,\ntheme every layer, make flat screens look dated.")
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.55))
                    .multilineTextAlignment(.center)
            }
            .padding(.top, 36)

            HStack(spacing: 10) {
                FeatureChip(symbol: "square.stack.3d.up", label: "9 blocks")
                FeatureChip(symbol: "paintbrush", label: "10 themes")
                FeatureChip(symbol: "lock", label: "On-device")
            }
            .padding(.top, 26)

            Spacer(minLength: 24)

            Button {
                Haptics.success()
                dismiss()
            } label: {
                Text("Start Designing")
                    .font(.headline)
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 15)
                    .glassPill(tint: Self.brand)
            }
            .buttonStyle(GlassButtonStyle())
            .padding(.horizontal, 28)
            .padding(.bottom, 34)
        }
        .frame(maxWidth: .infinity)
        .ambientBackground(tint: Self.brand)
        .preferredColorScheme(.dark)
        .interactiveDismissDisabled()
    }
}

private struct FeatureChip: View {
    let symbol: String
    let label: String

    var body: some View {
        Label(label, systemImage: symbol)
            .font(.footnote.weight(.medium))
            .foregroundStyle(.white.opacity(0.75))
            .padding(.horizontal, 12)
            .padding(.vertical, 7)
            .glassPill()
    }
}
