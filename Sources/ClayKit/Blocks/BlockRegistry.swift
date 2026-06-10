/**
 `BlockRegistry`: the static table of every block module this build knows.
 Unlike Cling's `PinRegistry` (which may `fatalError` — pin types come from
 code), an unknown kind here returns `nil`: kinds arrive from *data* that a
 newer app version may have written, and must degrade to a placeholder.

 Adding a block = one module file + one line in `all`.
 */
import Foundation

public enum BlockRegistry {
    /// Registration order = the order blocks appear in the editor's gallery.
    public static let all: [BlockHandle] = [
        BlockHandle(ClockBlock.self),
        BlockHandle(DateBlock.self),
        BlockHandle(WeatherBlock.self),
        BlockHandle(CalendarBlock.self),
        BlockHandle(BatteryBlock.self),
        BlockHandle(StepsBlock.self),
        BlockHandle(CountdownBlock.self),
        BlockHandle(QuoteBlock.self),
        BlockHandle(PhotoBlock.self),
    ]

    private static let byKind: [BlockKind: BlockHandle] =
        Dictionary(uniqueKeysWithValues: all.map { ($0.kind, $0) })

    /// `nil` for kinds this build doesn't know — render `UnknownBlockView`.
    public static func module(for kind: BlockKind) -> BlockHandle? {
        byKind[kind]
    }
}
