/**
 HealthKit steps provider. Two wrinkles drive its shape:
 - HealthKit hides read-authorization status for privacy, so "denied" is only
   detectable as a failed/empty query with no cached reading.
 - Reads fail while the device is locked — exactly when lock-screen widgets
   refresh — so the last reading is cached in the App Group and used whenever
   the live query can't answer.
 */
import Foundation
import HealthKit

public struct StepsProvider: SnapshotProviding {
    public let need = DataNeed.steps

    public init() {}

    public func contribute(
        to snapshot: inout BlockDataSnapshot, recipe: WidgetRecipe, at date: Date
    ) async {
        guard HKHealthStore.isHealthDataAvailable() else {
            snapshot.deniedNeeds.insert(.steps)
            return
        }

        let goal = recipe.blocks
            .first { $0.kind == .steps }?
            .config.decoded(as: StepsConfig.self, filling: StepsConfig()).goal ?? 10_000

        if let count = await querySteps() {
            let reading = StepsSnapshot(count: count, goal: goal, asOf: .now)
            Self.writeCache(reading)
            snapshot.steps = reading
        } else if let cached = Self.readCache(),
                  Calendar.current.isDate(cached.asOf, inSameDayAs: date) {
            // Locked-device read: today's last known count.
            snapshot.steps = StepsSnapshot(count: cached.count, goal: goal, asOf: cached.asOf)
        } else if Self.readCache() == nil {
            // Never succeeded → almost certainly not authorized.
            snapshot.deniedNeeds.insert(.steps)
        } else {
            snapshot.steps = StepsSnapshot(count: 0, goal: goal, asOf: date)
        }
    }

    private func querySteps() async -> Int? {
        let store = HKHealthStore()
        let stepType = HKQuantityType(.stepCount)
        let start = Calendar.current.startOfDay(for: .now)
        let predicate = HKQuery.predicateForSamples(withStart: start, end: .now)

        return await withCheckedContinuation { continuation in
            let query = HKStatisticsQuery(
                quantityType: stepType,
                quantitySamplePredicate: predicate,
                options: .cumulativeSum
            ) { _, statistics, error in
                guard error == nil, let sum = statistics?.sumQuantity() else {
                    continuation.resume(returning: nil)
                    return
                }
                continuation.resume(returning: Int(sum.doubleValue(for: .count())))
            }
            store.execute(query)
        }
    }

    // MARK: - App Group cache

    private static var cacheURL: URL? {
        FileManager.default
            .containerURL(forSecurityApplicationGroupIdentifier: ClayKit.appGroupID)?
            .appendingPathComponent("clay-steps-cache.v1.json")
    }

    static func readCache() -> StepsSnapshot? {
        guard let url = cacheURL,
              let data = try? Data(contentsOf: url) else { return nil }
        return try? JSONDecoder().decode(StepsSnapshot.self, from: data)
    }

    static func writeCache(_ reading: StepsSnapshot) {
        guard let url = cacheURL,
              let data = try? JSONEncoder().encode(reading) else { return }
        try? data.write(to: url, options: .atomic)
    }
}
