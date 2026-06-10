/**
 A process-stable 64-bit seed from a UUID. Swift's `hashValue` is randomized
 per process launch — useless for "the widget extension and the app must pick
 the same shuffle item." This folds the UUID's raw bytes instead.
 */
import Foundation

extension UUID {
    public var stableSeed: UInt64 {
        let b = uuid
        var seed: UInt64 = 0
        for byte in [b.0, b.1, b.2, b.3, b.4, b.5, b.6, b.7,
                     b.8, b.9, b.10, b.11, b.12, b.13, b.14, b.15] {
            seed = seed &* 31 &+ UInt64(byte)
        }
        return seed
    }
}
