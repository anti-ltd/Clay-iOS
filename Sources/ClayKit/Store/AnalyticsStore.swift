/**
 `AnalyticsStore`: on-device, private usage counts — nothing ever leaves the
 phone. The only thing tracked today is aquarium taps ("how many times did I
 make my fish swim"), broken down per tank.

 Like `RecipeStore`, state lives in a **file** in the App Group container, NOT
 App Group `UserDefaults`: the widget extension and the app are separate
 processes, and cfprefsd caches cross-process `UserDefaults` reads per process,
 so the app would read stale counts after a home-screen tap. A fresh
 `Data(contentsOf:)` always reflects the latest bytes on disk.

 Writes are read-modify-write. Two processes incrementing the exact same
 millisecond could lose one tap — acceptable for a personal vanity counter, and
 in practice you don't tap the in-app preview and the home-screen widget at the
 same instant.
 */
import Foundation

/// Snapshot of the aquarium tap counters.
public struct AquariumStats: Codable, Hashable, Sendable {
    /// Total swim taps across every tank, in-app and on the home screen.
    public var totalSwims: Int
    /// Swim taps keyed by tank (aquarium block instance UUID string).
    public var perTank: [String: Int]
    /// When the fish last swam.
    public var lastSwimAt: Date?

    public init(totalSwims: Int = 0, perTank: [String: Int] = [:], lastSwimAt: Date? = nil) {
        self.totalSwims = totalSwims
        self.perTank = perTank
        self.lastSwimAt = lastSwimAt
    }

    public static let empty = AquariumStats()
}

public final class AnalyticsStore: @unchecked Sendable {
    public static let shared = AnalyticsStore()

    private let appGroupID: String
    /// Serializes this process's own read-modify-write turns.
    private let lock = NSLock()

    public init(appGroupID: String = ClayKit.appGroupID) {
        self.appGroupID = appGroupID
    }

    private func containerURL() -> URL? {
        FileManager.default
            .containerURL(forSecurityApplicationGroupIdentifier: appGroupID)
    }

    /// `…/<AppGroup>/clay-analytics.v1.json`
    private var fileURL: URL? {
        containerURL()?.appendingPathComponent("clay-analytics.v1.json")
    }

    private static let fallbackKey = "clay-analytics-v1"

    // MARK: - Read

    public func aquariumStats() -> AquariumStats {
        lock.lock(); defer { lock.unlock() }
        return load()
    }

    private func load() -> AquariumStats {
        if let url = fileURL,
           let data = try? Data(contentsOf: url),
           let decoded = try? JSONDecoder().decode(AquariumStats.self, from: data) {
            return decoded
        }
        // App Group container unavailable (self-signed build without a matching
        // provisioning profile): keep counts within this process at least.
        if let data = UserDefaults.standard.data(forKey: Self.fallbackKey),
           let decoded = try? JSONDecoder().decode(AquariumStats.self, from: data) {
            return decoded
        }
        return .empty
    }

    // MARK: - Write

    /// Records one aquarium tap for the given tank (aquarium block instance id).
    public func recordAquariumSwim(tankID: String) {
        lock.lock(); defer { lock.unlock() }
        var stats = load()
        stats.totalSwims += 1
        stats.perTank[tankID, default: 0] += 1
        stats.lastSwimAt = Date()
        save(stats)
    }

    /// Wipes the counters (Settings "Reset").
    public func resetAquariumStats() {
        lock.lock(); defer { lock.unlock() }
        save(.empty)
    }

    private func save(_ stats: AquariumStats) {
        guard let data = try? JSONEncoder().encode(stats) else { return }
        if let url = fileURL {
            try? data.write(to: url, options: .atomic)
        } else {
            UserDefaults.standard.set(data, forKey: Self.fallbackKey)
        }
    }
}
