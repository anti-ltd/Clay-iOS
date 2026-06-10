/**
 Bundled quote packs: JSON in `Resources/Quotes/`, compiled into BOTH bundles
 (the extension picks quotes at timeline time). Decode failures skip the pack,
 never crash.
 */
import Foundation

public struct QuotePack: Codable, Identifiable, Sendable {
    public var id: String
    public var name: String
    public var quotes: [QuoteSnapshot]
}

public enum QuotePacks {
    public static let allPacks: [QuotePack] = load()

    public static func pack(id: String) -> QuotePack? {
        allPacks.first { $0.id == id }
    }

    /// Deterministic per-day pick: same day + same block = same quote in
    /// every process, no stored state. (`hashValue` is NOT stable across
    /// processes — seed from the UUID's raw bytes instead.)
    public static func quote(packID: String, date: Date, instanceID: UUID) -> QuoteSnapshot? {
        guard let pack = pack(id: packID), !pack.quotes.isEmpty else { return nil }
        let day = Calendar.current.ordinality(of: .day, in: .era, for: date) ?? 0
        let seed = UInt64(day) &* 31 &+ instanceID.stableSeed
        return pack.quotes[Int(seed % UInt64(pack.quotes.count))]
    }

    static func load() -> [QuotePack] {
        guard let urls = Bundle.main.urls(forResourcesWithExtension: "json", subdirectory: nil) else {
            return []
        }
        return urls
            .filter { $0.lastPathComponent.hasPrefix("quotes-") }
            .compactMap { url in
                guard let data = try? Data(contentsOf: url) else { return nil }
                return try? JSONDecoder().decode(QuotePack.self, from: data)
            }
            .sorted { $0.name < $1.name }
    }
}
