/**
 The honesty sheet: iOS offers no API to place widgets (or set wallpapers)
 programmatically, so this coach teaches the manual flow with illustrated
 steps. Reused everywhere recipes appear via "How do I add these?".
 */
import SwiftUI
import iUXiOS

struct AddToHomeScreenCoach: View {
    @Environment(\.dismiss) private var dismiss

    private struct Step: Identifiable {
        let id: Int
        let symbol: String
        let title: String
        let detail: String
    }

    private let steps: [Step] = [
        Step(id: 1, symbol: "hand.tap",
             title: "Long-press your home screen",
             detail: "Hold any empty spot until the apps jiggle."),
        Step(id: 2, symbol: "plus.circle",
             title: "Tap Edit, then Add Widget",
             detail: "In the top corner of the screen."),
        Step(id: 3, symbol: "magnifyingglass",
             title: "Search for Clay",
             detail: "Pick a size — small, medium, or large."),
        Step(id: 4, symbol: "square.and.pencil",
             title: "Choose your design",
             detail: "Long-press the new widget → Edit Widget → pick the design you made."),
        Step(id: 5, symbol: "lock",
             title: "Lock screen too",
             detail: "Long-press the lock screen → Customize → add Clay under widgets."),
    ]

    var body: some View {
        ScrollView {
            VStack(spacing: UX.cardSpacing) {
                Text("Add Your Widgets")
                    .font(.title2.weight(.semibold))
                    .padding(.top, 22)
                Text("Apple doesn't let apps place widgets for you — it takes a few taps, once.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 24)

                VStack(spacing: UX.cardSpacing) {
                    ForEach(steps) { step in
                        HStack(spacing: 14) {
                            Image(systemName: step.symbol)
                                .font(.system(size: 20, weight: .light))
                                .foregroundStyle(.tint)
                                .frame(width: 34)
                            VStack(alignment: .leading, spacing: 2) {
                                Text("\(step.id). \(step.title)")
                                    .font(.subheadline.weight(.semibold))
                                Text(step.detail)
                                    .font(.footnote)
                                    .foregroundStyle(.secondary)
                            }
                            Spacer(minLength: 0)
                        }
                        .padding(14)
                        .glassTile()
                    }
                }
                .padding(.horizontal, UX.screenPadding)

                Button {
                    dismiss()
                } label: {
                    Text("Got It")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .glassPill(tint: .accentColor)
                }
                .buttonStyle(GlassButtonStyle())
                .padding(.horizontal, UX.screenPadding)
                .padding(.bottom, UX.screenPadding)
            }
        }
        .glassSheet()
    }
}
