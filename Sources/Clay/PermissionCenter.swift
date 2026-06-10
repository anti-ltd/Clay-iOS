/**
 `PermissionCenter`: app-side status + request flows for the gated data needs.
 No forced prompts — the pitch card explains, the user decides, denial routes
 to Settings. The widget's "tap to enable" deep links land here.
 */
import CoreLocation
import EventKit
import HealthKit
import SwiftUI
import WidgetKit

enum PermissionStatus {
    case notDetermined
    case granted
    case denied
}

@Observable
@MainActor
final class PermissionCenter {
    @ObservationIgnored private lazy var locationManager = CLLocationManager()
    @ObservationIgnored private var locationDelegate: LocationAuthDelegate?

    private(set) var statuses: [DataNeed: PermissionStatus] = [:]

    init() {
        refresh()
    }

    func status(for need: DataNeed) -> PermissionStatus {
        statuses[need] ?? .notDetermined
    }

    func refresh() {
        statuses[.events] = Self.eventStatus()
        statuses[.weather] = locationStatus()
        // HealthKit hides read-auth status; report notDetermined until a
        // request has happened, then granted (reads degrade via cache anyway).
        if statuses[.steps] == nil { statuses[.steps] = .notDetermined }
    }

    func request(_ need: DataNeed) async {
        switch need {
        case .events:
            _ = try? await EKEventStore().requestFullAccessToEvents()
        case .weather:
            await requestLocation()
        case .steps:
            let store = HKHealthStore()
            try? await store.requestAuthorization(
                toShare: [], read: [HKQuantityType(.stepCount)])
            statuses[.steps] = .granted
        default:
            break
        }
        refresh()
        // Gated blocks may now have data — repaint widgets promptly.
        WidgetCenter.shared.reloadAllTimelines()
    }

    // MARK: - Statuses

    private static func eventStatus() -> PermissionStatus {
        switch EKEventStore.authorizationStatus(for: .event) {
        case .fullAccess: .granted
        case .notDetermined: .notDetermined
        default: .denied
        }
    }

    private func locationStatus() -> PermissionStatus {
        switch locationManager.authorizationStatus {
        case .authorizedWhenInUse, .authorizedAlways: .granted
        case .notDetermined: .notDetermined
        default: .denied
        }
    }

    private func requestLocation() async {
        guard locationManager.authorizationStatus == .notDetermined else { return }
        await withCheckedContinuation { (continuation: CheckedContinuation<Void, Never>) in
            let delegate = LocationAuthDelegate {
                continuation.resume()
            }
            locationDelegate = delegate
            locationManager.delegate = delegate
            locationManager.requestWhenInUseAuthorization()
        }
        locationDelegate = nil
    }
}

private final class LocationAuthDelegate: NSObject, CLLocationManagerDelegate {
    private var onChange: (() -> Void)?

    init(onChange: @escaping () -> Void) {
        self.onChange = onChange
    }

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        guard manager.authorizationStatus != .notDetermined else { return }
        onChange?()
        onChange = nil
    }
}
