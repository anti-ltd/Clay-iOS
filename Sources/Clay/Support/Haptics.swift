/**
 One-line haptics for editor interactions. iUX deliberately leaves haptics to
 host apps; this is Clay's single funnel so intensity stays consistent.
 */
import UIKit

@MainActor
enum Haptics {
    /// Chip taps, theme swaps, family switches.
    static func light() {
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
    }

    /// Block add/remove, reorder drop.
    static func medium() {
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
    }

    /// Save, setup applied.
    static func success() {
        UINotificationFeedbackGenerator().notificationOccurred(.success)
    }
}
