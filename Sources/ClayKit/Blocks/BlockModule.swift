/**
 The block plugin contract. One conforming type per block kind, registered in
 `BlockRegistry`, owning everything kind-specific: metadata, default config,
 the shared renderer, the timeline cadence, and the app-side config editor.

 `AnyView` at this boundary is deliberate (the PinModule precedent): the
 registry is heterogeneous, the view trees are tiny, and widget views are
 re-rendered wholesale by the system — there's no diffing win to protect.

 Adding a block = one new file conforming to this protocol and one registry
 line. See ARCHITECTURE.md.

 Isolation: metadata and `timelineNeed` are `nonisolated` (pure values — the
 timeline provider reads them off-main), while `render`/`configEditor` are
 `@MainActor` (SwiftUI `body` is MainActor in both processes).
 */
import SwiftUI

/// Render-environment facts that aren't data: where the view is running and
/// at what size. Lets renderers adapt (accessory families render monochrome,
/// small families drop secondary lines) without sniffing the environment.
public struct BlockRenderContext: Sendable {
    public let family: WidgetFamilyKey
    /// True in the widget extension, false in the in-app preview. Renderers
    /// must NOT branch visual styling on this — it exists for capability
    /// differences only (e.g. `widgetAccentable`).
    public let isInWidget: Bool
    /// The rendered block's instance id — the key into the snapshot's
    /// per-instance selections (photo shuffle, quote of the day).
    public let instanceID: UUID

    public init(family: WidgetFamilyKey, isInWidget: Bool, instanceID: UUID = UUID()) {
        self.family = family
        self.isInWidget = isInWidget
        self.instanceID = instanceID
    }
}

public protocol BlockModule {
    associatedtype Config: Codable & Hashable & Sendable

    nonisolated static var kind: BlockKind { get }
    nonisolated static var displayName: String { get }
    nonisolated static var systemImage: String { get }
    nonisolated static var defaultConfig: Config { get }
    nonisolated static var supportedFamilies: Set<WidgetFamilyKey> { get }
    /// Runtime data the renderer consumes. Drives snapshot resolution and
    /// permission gating. Empty for self-contained blocks.
    nonisolated static var dataNeeds: Set<DataNeed> { get }
    /// Non-nil for permission-gated blocks (calendar, weather, steps).
    nonisolated static var permission: PermissionRequirement? { get }

    /// Pure, synchronous render. Runs identically in the app preview and in
    /// widget timeline entries — never reads the wall clock or a data source.
    @MainActor static func render(
        config: Config,
        style: ResolvedBlockStyle,
        snapshot: BlockDataSnapshot,
        context: BlockRenderContext
    ) -> AnyView

    /// The refresh cadence this block needs given its config.
    nonisolated static func timelineNeed(config: Config) -> TimelineNeed

    /// App-side config editor — the type-specific section of the block
    /// inspector. Built from iUX rows/chips/sliders.
    @MainActor static func configEditor(config: Binding<Config>) -> AnyView
}

public extension BlockModule {
    nonisolated static var dataNeeds: Set<DataNeed> { [] }
    nonisolated static var permission: PermissionRequirement? { nil }
    nonisolated static var supportedFamilies: Set<WidgetFamilyKey> { Set(WidgetFamilyKey.allCases) }
    nonisolated static func timelineNeed(config: Config) -> TimelineNeed { .staticEntry }
}

// MARK: - Type erasure

/// The registry-facing face of a module: a plain value built generically from
/// the typed module — closures bridge `JSONValue` → `Config`, falling back to
/// `defaultConfig` on mismatch, so a config written by a newer version never
/// crashes an older renderer. (A value type with closures, not an existential
/// metatype: composed protocol-metatype dispatch crashes the Swift 6 SILGen.)
public struct BlockHandle: Sendable, Identifiable {
    public let kind: BlockKind
    public let displayName: String
    public let systemImage: String
    public let supportedFamilies: Set<WidgetFamilyKey>
    public let dataNeeds: Set<DataNeed>
    public let permission: PermissionRequirement?
    public let defaultConfig: JSONValue

    public var id: String { kind.rawValue }

    private let renderInstance: @MainActor (
        BlockInstance, ResolvedBlockStyle, BlockDataSnapshot, BlockRenderContext
    ) -> AnyView
    private let timelineNeedInstance: @Sendable (BlockInstance) -> TimelineNeed
    private let configEditorInstance: @MainActor (Binding<BlockInstance>) -> AnyView

    public init<M: BlockModule>(_ module: M.Type) {
        kind = M.kind
        displayName = M.displayName
        systemImage = M.systemImage
        supportedFamilies = M.supportedFamilies
        dataNeeds = M.dataNeeds
        permission = M.permission
        defaultConfig = (try? JSONValue(encoding: M.defaultConfig)) ?? .object([:])

        renderInstance = { instance, style, snapshot, context in
            let config = instance.config.decoded(as: M.Config.self, filling: M.defaultConfig)
            return M.render(config: config, style: style, snapshot: snapshot, context: context)
        }
        timelineNeedInstance = { instance in
            M.timelineNeed(config: instance.config.decoded(as: M.Config.self, filling: M.defaultConfig))
        }
        configEditorInstance = { instance in
            // Bridge the opaque JSONValue through a typed binding: reads
            // decode (defaulting on mismatch), writes re-encode.
            let typed = Binding<M.Config>(
                get: { instance.wrappedValue.config.decoded(as: M.Config.self, filling: M.defaultConfig) },
                set: { instance.wrappedValue.config = (try? JSONValue(encoding: $0)) ?? instance.wrappedValue.config }
            )
            return M.configEditor(config: typed)
        }
    }

    @MainActor
    public func render(
        instance: BlockInstance,
        style: ResolvedBlockStyle,
        snapshot: BlockDataSnapshot,
        context: BlockRenderContext
    ) -> AnyView {
        renderInstance(instance, style, snapshot, context)
    }

    public func timelineNeed(instance: BlockInstance) -> TimelineNeed {
        timelineNeedInstance(instance)
    }

    @MainActor
    public func configEditor(instance: Binding<BlockInstance>) -> AnyView {
        configEditorInstance(instance)
    }
}
