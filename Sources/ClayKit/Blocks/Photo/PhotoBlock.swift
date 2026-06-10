/**
 Photo block — single or hourly shuffle. Images live as files in the App Group
 (`PhotoStore`); the config carries filenames only, and the snapshot carries
 THIS entry's pick so app and widget show the same frame.
 */
import SwiftUI
import iUXiOS

public struct PhotoConfig: Codable, Hashable, Sendable {
    public var mode: String           // "single" | "shuffle"
    public var filenames: [String]

    public init(mode: String = "single", filenames: [String] = []) {
        self.mode = mode
        self.filenames = filenames
    }

    public var isShuffle: Bool { mode == "shuffle" }

    /// Deterministic pick for an entry date — shared by the provider (which
    /// writes it into the snapshot) and previews.
    public func filename(at date: Date, instanceID: UUID) -> String? {
        guard !filenames.isEmpty else { return nil }
        guard isShuffle else { return filenames.first }
        let hour = Int(date.timeIntervalSinceReferenceDate / 3600)
        let seed = UInt64(hour) &* 31 &+ instanceID.stableSeed
        return filenames[Int(seed % UInt64(filenames.count))]
    }
}

public enum PhotoBlock: BlockModule {
    public static let kind = BlockKind.photo
    public static let displayName = "Photo"
    public static let systemImage = "photo.on.rectangle.angled"
    public static let defaultConfig = PhotoConfig()
    public static let dataNeeds: Set<DataNeed> = [.photos]
    public static let supportedFamilies: Set<WidgetFamilyKey> = [.small, .medium, .large]

    public nonisolated static func timelineNeed(config: PhotoConfig) -> TimelineNeed {
        config.isShuffle && config.filenames.count > 1 ? .every(3600) : .staticEntry
    }

    @MainActor
    public static func render(
        config: PhotoConfig,
        style: ResolvedBlockStyle,
        snapshot: BlockDataSnapshot,
        context: BlockRenderContext
    ) -> AnyView {
        let filename = snapshot.photoSelection[context.instanceID]
            ?? config.filename(at: snapshot.date, instanceID: context.instanceID)
        let image = filename.flatMap { PhotoStore.shared.loadImage($0).map(Image.init(uiImage:)) }
        return AnyView(PhotoBlockView(image: image, style: style))
    }

    @MainActor
    public static func configEditor(config: Binding<PhotoConfig>) -> AnyView {
        AnyView(PhotoConfigEditor(config: config))
    }
}

private struct PhotoBlockView: View {
    let image: Image?
    let style: ResolvedBlockStyle

    var body: some View {
        GeometryReader { proxy in
            if let image {
                image
                    .resizable()
                    .scaledToFill()
                    .frame(width: proxy.size.width, height: proxy.size.height)
                    .clipShape(RoundedRectangle(
                        cornerRadius: style.corner.radius * 0.6,
                        style: style.corner.continuous ? .continuous : .circular))
            } else {
                GlassThumb(
                    image: nil,
                    size: proxy.size,
                    placeholderSymbol: "photo",
                    tint: style.tintColor)
            }
        }
    }
}

/// The picker itself (PhotosPicker needs the app process) lives app-side in
/// `PhotoPickerRow`; ClayKit keeps the editor framework-free for the widget
/// target by injecting it through this hook.
@MainActor
public enum PhotoBlockEditorHook {
    /// Set by the app at launch; renders the photo-picking UI for a config.
    public static var makePicker: (@MainActor (Binding<PhotoConfig>) -> AnyView)?
}

private struct PhotoConfigEditor: View {
    @Binding var config: PhotoConfig

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            OptionChips(
                options: [("Single", "single"), ("Shuffle Hourly", "shuffle")],
                selection: $config.mode)
                .padding(.vertical, UX.rowVPadding)
            Divider()
            if let makePicker = PhotoBlockEditorHook.makePicker {
                makePicker($config)
            } else {
                Text("\(config.filenames.count) photo(s)")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .padding(.vertical, UX.rowVPadding)
            }
        }
    }
}
