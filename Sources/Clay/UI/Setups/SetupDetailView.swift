/**
 One setup: every recipe previewed live, the wallpaper suggestion, and the
 apply flow — copy recipes into the library (fresh UUIDs), offer the wallpaper
 to Photos (rendered via ImageRenderer; iOS can't set wallpapers), then coach
 the manual add.
 */
import SwiftUI
import iUXiOS

struct SetupDetailView: View {
    @Environment(AppModel.self) private var model

    let setup: Setup

    @State private var applied = false
    @State private var showingCoach = false
    @State private var wallpaperSaved = false

    var body: some View {
        ScrollView {
            VStack(spacing: UX.cardSpacing) {
                Text(setup.blurb)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 24)

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 14) {
                        ForEach(setup.recipes) { recipe in
                            VStack(spacing: 8) {
                                ScaledWidgetPreview(
                                    recipe: recipe,
                                    fitWidth: WidgetFamilyMetrics.pointSize(for: .small).width)
                                Text(recipe.name)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                    .padding(.horizontal, UX.screenPadding)
                    .padding(.vertical, 8)
                }

                if let gradient = setup.wallpaper?.gradient {
                    CardSection("Wallpaper Pairing") {
                        HStack(spacing: 14) {
                            LinearGradientSpecView(spec: gradient)
                                .frame(width: 56, height: 100)
                                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Save it, then set it from Photos — iOS keeps wallpaper to itself.")
                                    .font(.footnote)
                                    .foregroundStyle(.secondary)
                                Button {
                                    saveWallpaper(gradient)
                                } label: {
                                    Label(
                                        wallpaperSaved ? "Saved" : "Save to Photos",
                                        systemImage: wallpaperSaved ? "checkmark" : "square.and.arrow.down")
                                        .font(.subheadline.weight(.medium))
                                }
                                .buttonStyle(GlassButtonStyle())
                                .disabled(wallpaperSaved)
                            }
                            Spacer(minLength: 0)
                        }
                        .padding(.vertical, UX.rowVPadding)
                    }
                }

                Button {
                    apply()
                } label: {
                    Label(
                        applied ? "Added to My Widgets" : "Use This Setup",
                        systemImage: applied ? "checkmark.circle.fill" : "sparkles")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .glassPill(tint: .accentColor)
                }
                .buttonStyle(GlassButtonStyle())
                .disabled(applied)

                Button("How do I add these to my home screen?") {
                    showingCoach = true
                }
                .font(.footnote)
                .foregroundStyle(.secondary)
                .padding(.bottom, UX.screenPadding)
            }
            .padding(.horizontal, UX.screenPadding)
        }
        .navigationTitle(setup.name)
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showingCoach) {
            AddToHomeScreenCoach()
        }
    }

    private func apply() {
        for recipe in setup.recipes {
            var copy = recipe
            copy.id = UUID()
            copy.createdAt = .now
            model.upsert(copy)
        }
        applied = true
        Haptics.success()
        showingCoach = true
    }

    @MainActor
    private func saveWallpaper(_ gradient: GradientSpec) {
        let size = UIScreen.main.bounds.size
        let renderer = ImageRenderer(content:
            LinearGradientSpecView(spec: gradient)
                .frame(width: size.width, height: size.height))
        renderer.scale = UIScreen.main.scale
        guard let image = renderer.uiImage else { return }
        UIImageWriteToSavedPhotosAlbum(image, nil, nil, nil)
        wallpaperSaved = true
        Haptics.success()
    }
}
