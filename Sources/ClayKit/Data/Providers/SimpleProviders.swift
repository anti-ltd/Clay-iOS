/**
 The self-contained providers: battery (UIDevice sample), photo selection
 (deterministic pick from the block's own filenames), quote selection
 (deterministic pick from bundled packs). No permissions, no caching needed.
 */
import Foundation
#if canImport(UIKit)
import UIKit
#endif

public struct BatteryProvider: SnapshotProviding {
    public let need = DataNeed.battery

    public init() {}

    public func contribute(
        to snapshot: inout BlockDataSnapshot, recipe: WidgetRecipe, at date: Date
    ) async {
        #if canImport(UIKit)
        let reading = await MainActor.run { () -> BatterySnapshot in
            let device = UIDevice.current
            device.isBatteryMonitoringEnabled = true
            let level = device.batteryLevel
            return BatterySnapshot(
                level: level < 0 ? 1 : Double(level),
                isCharging: device.batteryState == .charging || device.batteryState == .full)
        }
        snapshot.battery = reading
        #endif
    }
}

public struct PhotoSelectionProvider: SnapshotProviding {
    public let need = DataNeed.photos

    public init() {}

    public func contribute(
        to snapshot: inout BlockDataSnapshot, recipe: WidgetRecipe, at date: Date
    ) async {
        for block in recipe.blocks where block.kind == .photo {
            let config = block.config.decoded(as: PhotoConfig.self, filling: PhotoConfig())
            guard
                  let filename = config.filename(at: date, instanceID: block.id) else { continue }
            snapshot.photoSelection[block.id] = filename
        }
    }
}

public struct QuoteSelectionProvider: SnapshotProviding {
    public let need = DataNeed.time

    public init() {}

    public func contribute(
        to snapshot: inout BlockDataSnapshot, recipe: WidgetRecipe, at date: Date
    ) async {
        for block in recipe.blocks where block.kind == .quote {
            let config = block.config.decoded(as: QuoteConfig.self, filling: QuoteConfig())
            if config.isCustom {
                let text = config.customText.isEmpty ? "Dress your phone." : config.customText
                snapshot.quoteSelection[block.id] = QuoteSnapshot(
                    text: text, attribution: config.customAttribution)
            } else if let quote = QuotePacks.quote(
                packID: config.packID, date: date, instanceID: block.id) {
                snapshot.quoteSelection[block.id] = quote
            }
        }
    }
}
