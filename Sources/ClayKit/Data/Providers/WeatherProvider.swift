/**
 WeatherKit provider with an App Group cache (25-min TTL): N timeline entries
 and back-to-back widget reloads read the disk, not the network — the budget
 discipline the plan promises. Location comes from the last known fix
 (`NSWidgetWantsLocation` lets the extension have one); no async delegate
 dance inside a timeline call.
 */
import CoreLocation
import Foundation
import WeatherKit

public struct WeatherProvider: SnapshotProviding {
    public let need = DataNeed.weather

    private static let cacheTTL: TimeInterval = 25 * 60

    public init() {}

    public func contribute(
        to snapshot: inout BlockDataSnapshot, recipe: WidgetRecipe, at date: Date
    ) async {
        let status = locationStatus()
        guard status == .authorizedWhenInUse || status == .authorizedAlways else {
            snapshot.deniedNeeds.insert(.weather)
            // A cached reading still beats a placeholder while undetermined.
            if status == .notDetermined, let cached = Self.readCache() {
                snapshot.weather = cached
                snapshot.deniedNeeds.remove(.weather)
            }
            return
        }

        // Fresh-enough cache wins outright.
        if let cached = Self.readCache(),
           Date.now.timeIntervalSince(cached.asOf) < Self.cacheTTL {
            snapshot.weather = cached
            return
        }

        guard let location = await currentLocation() else {
            snapshot.weather = Self.readCache() // stale beats nothing
            return
        }

        do {
            let weather = try await WeatherService.shared.weather(for: location)
            let day = weather.dailyForecast.first
            let reading = WeatherSnapshot(
                temperature: weather.currentWeather.temperature.converted(to: .celsius).value,
                highTemperature: day?.highTemperature.converted(to: .celsius).value
                    ?? weather.currentWeather.temperature.converted(to: .celsius).value,
                lowTemperature: day?.lowTemperature.converted(to: .celsius).value
                    ?? weather.currentWeather.temperature.converted(to: .celsius).value,
                symbolName: weather.currentWeather.symbolName + ".fill",
                conditionDescription: weather.currentWeather.condition.description,
                asOf: .now)
            Self.writeCache(reading)
            snapshot.weather = reading
        } catch {
            snapshot.weather = Self.readCache() // offline: stale beats nothing
        }
    }

    private func locationStatus() -> CLAuthorizationStatus {
        CLLocationManager().authorizationStatus
    }

    private func currentLocation() async -> CLLocation? {
        if let last = CLLocationManager().location { return last }
        // One fresh fix; bail quietly on failure.
        return await withCheckedContinuation { continuation in
            OneShotLocation.request { location in
                continuation.resume(returning: location)
            }
        }
    }

    // MARK: - App Group cache

    private static var cacheURL: URL? {
        FileManager.default
            .containerURL(forSecurityApplicationGroupIdentifier: ClayKit.appGroupID)?
            .appendingPathComponent("clay-weather-cache.v1.json")
    }

    static func readCache() -> WeatherSnapshot? {
        guard let url = cacheURL,
              let data = try? Data(contentsOf: url) else { return nil }
        return try? JSONDecoder().decode(WeatherSnapshot.self, from: data)
    }

    static func writeCache(_ reading: WeatherSnapshot) {
        guard let url = cacheURL,
              let data = try? JSONEncoder().encode(reading) else { return }
        try? data.write(to: url, options: .atomic)
    }
}

/// Owns BOTH the manager and the callback for the request's full duration —
/// a stack-local `CLLocationManager` deallocates when the spawning function
/// returns, killing the request before the delegate ever fires. Instances
/// retain themselves in `active` until they finish.
private final class OneShotLocation: NSObject, CLLocationManagerDelegate, @unchecked Sendable {
    private static let lock = NSLock()
    nonisolated(unsafe) private static var active: [OneShotLocation] = []

    private let manager = CLLocationManager()
    private var completion: ((CLLocation?) -> Void)?

    static func request(_ completion: @escaping (CLLocation?) -> Void) {
        let shot = OneShotLocation()
        shot.completion = completion
        lock.lock()
        active.append(shot)
        lock.unlock()
        shot.manager.delegate = shot
        shot.manager.requestLocation()
    }

    private func finish(_ location: CLLocation?) {
        completion?(location)
        completion = nil
        Self.lock.lock()
        Self.active.removeAll { $0 === self }
        Self.lock.unlock()
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        finish(locations.first)
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        finish(nil)
    }
}
