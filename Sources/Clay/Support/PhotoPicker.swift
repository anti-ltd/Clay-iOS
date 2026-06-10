/**
 The app-side photo picking row injected into PhotoBlock's config editor
 (PhotosUI needs the app process; ClayKit stays framework-free for the widget
 target). Registered once at app launch via `PhotoBlockEditorHook`.
 */
import PhotosUI
import SwiftUI
import iUXiOS

@MainActor
enum PhotoPickerRegistration {
    static func register() {
        PhotoBlockEditorHook.makePicker = { binding in
            AnyView(PhotoPickerRow(config: binding))
        }
    }
}

private struct PhotoPickerRow: View {
    @Binding var config: PhotoConfig
    @State private var selection: [PhotosPickerItem] = []

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            PhotosPicker(
                selection: $selection,
                maxSelectionCount: config.isShuffle ? 20 : 1,
                matching: .images
            ) {
                Label(
                    config.filenames.isEmpty ? "Choose Photos" : "Change Photos",
                    systemImage: "photo.badge.plus")
                    .font(.subheadline.weight(.medium))
            }
            .buttonStyle(GlassButtonStyle())
            .padding(.vertical, UX.rowVPadding)

            if !config.filenames.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(config.filenames, id: \.self) { filename in
                            GlassThumb(
                                image: PhotoStore.shared.loadImage(filename)
                                    .map(Image.init(uiImage:)),
                                size: CGSize(width: 52, height: 52))
                                .overlay(alignment: .topTrailing) {
                                    Button {
                                        remove(filename)
                                    } label: {
                                        Image(systemName: "xmark.circle.fill")
                                            .font(.system(size: 14))
                                            .foregroundStyle(.white, .black.opacity(0.5))
                                    }
                                    .offset(x: 4, y: -4)
                                }
                        }
                    }
                    .padding(.top, 4)
                }
                .padding(.bottom, UX.rowVPadding)
            }
        }
        .onChange(of: selection) {
            Task { await importSelection() }
        }
    }

    private func remove(_ filename: String) {
        config.filenames.removeAll { $0 == filename }
        PhotoStore.shared.delete(filename)
    }

    private func importSelection() async {
        guard !selection.isEmpty else { return }
        var imported: [String] = []
        for item in selection {
            guard let data = try? await item.loadTransferable(type: Data.self),
                  let image = UIImage(data: data),
                  let filename = PhotoStore.shared.save(image) else { continue }
            imported.append(filename)
        }
        selection = []
        guard !imported.isEmpty else { return }
        // Single replaces; shuffle accumulates.
        if config.isShuffle {
            config.filenames.append(contentsOf: imported)
        } else {
            config.filenames.forEach { PhotoStore.shared.delete($0) }
            config.filenames = imported
        }
    }
}
