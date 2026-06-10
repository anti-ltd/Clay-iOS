/**
 `PhotoStore`: photo-block images as files in the App Group container. Configs
 carry only the *filename* — the widget process shares the container and loads
 the bytes itself. Same pattern as Cling's pin photos.
 */
import Foundation
#if canImport(UIKit)
import UIKit
#endif

public final class PhotoStore: @unchecked Sendable {
    public static let shared = PhotoStore()

    private let appGroupID: String

    public init(appGroupID: String = ClayKit.appGroupID) {
        self.appGroupID = appGroupID
    }

    /// `…/<AppGroup>/clay-photos/`, created on demand. Falls back to Caches
    /// when the App Group is unavailable (unprovisioned dev build) — photos
    /// then don't reach the widget, but nothing crashes.
    private var directoryURL: URL? {
        let base = FileManager.default
            .containerURL(forSecurityApplicationGroupIdentifier: appGroupID)
            ?? FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first
        guard let dir = base?.appendingPathComponent("clay-photos", isDirectory: true) else { return nil }
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir
    }

    public func url(for filename: String) -> URL? {
        directoryURL?.appendingPathComponent(filename)
    }

    /// Persist already-encoded image data. Returns the filename to store in
    /// the block config.
    public func save(_ data: Data, fileExtension: String = "jpg") -> String? {
        let filename = "\(UUID().uuidString).\(fileExtension)"
        guard let url = url(for: filename),
              (try? data.write(to: url, options: .atomic)) != nil else { return nil }
        return filename
    }

    #if canImport(UIKit)
    /// Downscale + JPEG-encode + persist. 1200px fills a large widget at 3x
    /// comfortably while staying well inside the extension's ~30MB memory cap.
    public func save(_ image: UIImage, maxDimension: CGFloat = 1200) -> String? {
        let scale = min(1, maxDimension / max(image.size.width, image.size.height))
        let target = CGSize(width: image.size.width * scale, height: image.size.height * scale)
        let renderer = UIGraphicsImageRenderer(size: target)
        let scaled = renderer.image { _ in
            image.draw(in: CGRect(origin: .zero, size: target))
        }
        guard let data = scaled.jpegData(compressionQuality: 0.85) else { return nil }
        return save(data)
    }

    public func loadImage(_ filename: String) -> UIImage? {
        guard let url = url(for: filename) else { return nil }
        return UIImage(contentsOfFile: url.path)
    }
    #endif

    public func delete(_ filename: String) {
        guard let url = url(for: filename) else { return }
        try? FileManager.default.removeItem(at: url)
    }

    /// Remove photos no recipe references anymore. The app calls this on
    /// launch with the filenames currently in the store.
    public func reapOrphans(referenced: Set<String>) {
        guard let dir = directoryURL,
              let files = try? FileManager.default.contentsOfDirectory(atPath: dir.path) else { return }
        for file in files where !referenced.contains(file) {
            try? FileManager.default.removeItem(at: dir.appendingPathComponent(file))
        }
    }
}
